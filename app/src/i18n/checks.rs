//! Release gates for the message catalogs, run as unit tests:
//!
//! - every catalog parses without junk, duplicate ids, terms or attributes;
//! - every `t!` call in the app (found by lexing the Rust sources and parsing
//!   the macro's arguments as Rust, whatever the macro's path or delimiter)
//!   names a source message and passes exactly the variables that message
//!   uses;
//! - every translation defines every source message, uses exactly the
//!   source's variables, uses only plural categories its language has,
//!   references only messages that exist (checked statically on the syntax
//!   tree, with cycle detection, so every branch counts), shows every text
//!   variable on every branch (also statically), and formats *on its own*,
//!   with no fallback, without a single Fluent error for representative
//!   counts plus every exact numeric variant it declares;
//! - the playbook translations match the options the built-in manifest
//!   declares;
//! - mutation tests prove the gate rejects a broken reference (including one
//!   hidden in an unsampled branch), a cycle, a dropped variable, a variable
//!   missing from one branch, and a bad plural category.

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;
use std::str::FromStr;

use fluent_bundle::FluentArgs;
use fluent_langneg::{LanguageIdentifier, NegotiationStrategy, negotiate_languages};
use fluent_syntax::ast::{Entry, Expression, InlineExpression, Pattern, PatternElement, VariantKey};
use fluent_syntax::parser;
use intl_pluralrules::{PluralRuleType, PluralRules};
use proc_macro2::{TokenStream, TokenTree};

use super::catalog::{self, Arg, LOCALES, Locale, compile};

/// A parsed catalog: what each message references.
struct Parsed {
    messages: BTreeMap<String, MessageInfo>,
}

#[derive(Default, Debug)]
struct MessageInfo {
    variables: BTreeSet<String>,
    /// Variables used as selectors.
    selectors: BTreeSet<String>,
    /// Identifier variant keys, per selector variable.
    category_keys: BTreeMap<String, BTreeSet<String>>,
    /// Exact numeric variant keys, so the gate samples them.
    numeric_keys: BTreeSet<i64>,
    /// Messages referenced anywhere in the value, including inside variants.
    references: BTreeSet<String>,
    /// Function names referenced.
    functions: BTreeSet<String>,
    /// Text variables the message shows on every branch (see `always_shows`).
    always_shown: BTreeSet<String>,
}

fn collect_pattern(pattern: &Pattern<&str>, info: &mut MessageInfo) {
    for element in &pattern.elements {
        if let PatternElement::Placeable { expression } = element {
            collect_expression(expression, info);
        }
    }
}

fn collect_inline(expression: &InlineExpression<&str>, info: &mut MessageInfo) -> Option<String> {
    match expression {
        InlineExpression::VariableReference { id } => {
            info.variables.insert(id.name.to_owned());
            Some(id.name.to_owned())
        }
        InlineExpression::FunctionReference { id, arguments } => {
            info.functions.insert(id.name.to_owned());
            for argument in &arguments.positional {
                collect_inline(argument, info);
            }
            for named in &arguments.named {
                collect_inline(&named.value, info);
            }
            None
        }
        InlineExpression::Placeable { expression } => {
            collect_expression(expression, info);
            None
        }
        InlineExpression::MessageReference { id, .. } => {
            info.references.insert(id.name.to_owned());
            None
        }
        InlineExpression::TermReference { id, arguments, .. } => {
            info.references.insert(format!("-{}", id.name));
            if let Some(arguments) = arguments {
                for named in &arguments.named {
                    collect_inline(&named.value, info);
                }
            }
            None
        }
        InlineExpression::StringLiteral { .. } | InlineExpression::NumberLiteral { .. } => None,
    }
}

fn collect_expression(expression: &Expression<&str>, info: &mut MessageInfo) {
    match expression {
        Expression::Inline(inline) => {
            collect_inline(inline, info);
        }
        Expression::Select { selector: chosen, variants } => {
            let name = collect_inline(chosen, info);
            if let Some(name) = &name {
                info.selectors.insert(name.clone());
            }
            for variant in variants {
                match &variant.key {
                    VariantKey::Identifier { name: key } => {
                        if let Some(name) = &name {
                            info.category_keys.entry(name.clone()).or_default().insert((*key).to_owned());
                        }
                    }
                    VariantKey::NumberLiteral { value } => {
                        if let Ok(number) = value.parse::<i64>() {
                            info.numeric_keys.insert(number);
                        }
                    }
                }
                collect_pattern(&variant.value, info);
            }
        }
    }
}

/// Whether every way through `pattern` shows the variable `name` as text:
/// a direct placeable, or a select every one of whose variants does. A
/// select whose selector is the variable does not count as showing it.
fn always_shows(pattern: &Pattern<&str>, name: &str) -> bool {
    pattern.elements.iter().any(|element| match element {
        PatternElement::TextElement { .. } => false,
        PatternElement::Placeable { expression } => expression_always_shows(expression, name),
    })
}

fn expression_always_shows(expression: &Expression<&str>, name: &str) -> bool {
    match expression {
        Expression::Inline(InlineExpression::VariableReference { id }) => id.name == name,
        Expression::Inline(InlineExpression::Placeable { expression }) => {
            expression_always_shows(expression, name)
        }
        Expression::Inline(_) => false,
        Expression::Select { variants, .. } => {
            variants.iter().all(|variant| always_shows(&variant.value, name))
        }
    }
}

/// Parses a catalog's text, reporting structural problems instead of
/// panicking so mutation tests can assert on them.
fn parse_text(tag: &str, ftl: &str) -> Result<Parsed, Vec<String>> {
    let mut problems = Vec::new();
    let resource = match parser::parse(ftl) {
        Ok(resource) => resource,
        Err((resource, errors)) => {
            for error in errors {
                problems.push(format!("{tag}: syntax error: {error:?}"));
            }
            resource
        }
    };
    let mut messages = BTreeMap::new();
    for entry in &resource.body {
        match entry {
            Entry::Message(message) => {
                let mut info = MessageInfo::default();
                if let Some(value) = &message.value {
                    collect_pattern(value, &mut info);
                    info.always_shown = info
                        .variables
                        .iter()
                        .filter(|variable| always_shows(value, variable))
                        .cloned()
                        .collect();
                } else {
                    problems.push(format!("{tag}: {} has no value", message.id.name));
                }
                if !message.attributes.is_empty() {
                    problems.push(format!(
                        "{tag}: {} uses attributes; the app reads values only",
                        message.id.name
                    ));
                }
                if messages.insert(message.id.name.to_owned(), info).is_some() {
                    problems.push(format!("{tag}: duplicate message {}", message.id.name));
                }
            }
            Entry::Term(term) => problems.push(format!("{tag}: terms are not used ({})", term.id.name)),
            Entry::Junk { content } => problems.push(format!("{tag}: junk in catalog: {content:?}")),
            Entry::Comment(_) | Entry::GroupComment(_) | Entry::ResourceComment(_) => {}
        }
    }
    if problems.is_empty() { Ok(Parsed { messages }) } else { Err(problems) }
}

fn parse(locale: &Locale) -> Parsed {
    parse_text(locale.tag, locale.ftl).unwrap_or_else(|problems| panic!("{}", problems.join("\n")))
}

/// Static reference checks over the whole syntax tree: every referenced
/// message exists in the same catalog (no terms), and no reference chain
/// loops. Covers every branch, sampled or not.
fn reference_problems(tag: &str, parsed: &Parsed) -> Vec<String> {
    let mut problems = Vec::new();
    for (id, info) in &parsed.messages {
        for target in &info.references {
            if target.starts_with('-') {
                problems.push(format!("{tag}: {id} references a term ({target}); terms are not used"));
            } else if !parsed.messages.contains_key(target) {
                problems.push(format!("{tag}: {id} references a message that does not exist: {target}"));
            }
        }
    }
    // Depth-first search for cycles.
    #[derive(Clone, Copy, PartialEq)]
    enum Mark {
        Visiting,
        Done,
    }
    let mut marks: BTreeMap<&str, Mark> = BTreeMap::new();
    fn visit<'a>(
        id: &'a str,
        parsed: &'a Parsed,
        marks: &mut BTreeMap<&'a str, Mark>,
        path: &mut Vec<&'a str>,
        problems: &mut Vec<String>,
        tag: &str,
    ) {
        match marks.get(id) {
            Some(Mark::Done) => return,
            Some(Mark::Visiting) => {
                problems
                    .push(format!("{tag}: message references form a cycle: {} -> {id}", path.join(" -> ")));
                return;
            }
            None => {}
        }
        marks.insert(id, Mark::Visiting);
        path.push(id);
        if let Some(info) = parsed.messages.get(id) {
            for target in &info.references {
                if parsed.messages.contains_key(target) {
                    visit(target, parsed, marks, path, problems, tag);
                }
            }
        }
        path.pop();
        marks.insert(id, Mark::Done);
    }
    for id in parsed.messages.keys() {
        visit(id, parsed, &mut marks, &mut Vec::new(), &mut problems, tag);
    }
    problems
}

// ----- The t! scanner -------------------------------------------------------

/// Every `t!` invocation in the app's Rust sources, found by lexing the
/// files: `t!(...)`, `crate::t!(...)`, `t! { ... }` and `t![...]` all count,
/// comments and string literals do not. Arguments are parsed as Rust, so a
/// comma inside a turbofish or a nested call is not a separator.
fn macro_uses(root: &Path) -> Vec<(String, String, BTreeSet<String>)> {
    let mut uses = Vec::new();
    for entry in walk(root) {
        let text = std::fs::read_to_string(&entry).unwrap();
        let file = entry.strip_prefix(root).unwrap_or(&entry).display().to_string();
        let stream =
            TokenStream::from_str(&text).unwrap_or_else(|error| panic!("{file}: does not lex: {error}"));
        scan_stream(stream, &file, &mut uses);
    }
    uses
}

fn scan_stream(stream: TokenStream, file: &str, uses: &mut Vec<(String, String, BTreeSet<String>)>) {
    let tokens: Vec<TokenTree> = stream.into_iter().collect();
    for (index, token) in tokens.iter().enumerate() {
        if let TokenTree::Group(group) = token {
            scan_stream(group.stream(), file, uses);
            continue;
        }
        let TokenTree::Ident(ident) = token else { continue };
        if ident != "t" {
            continue;
        }
        let bang = matches!(tokens.get(index + 1), Some(TokenTree::Punct(punct)) if punct.as_char() == '!');
        let Some(TokenTree::Group(arguments)) = tokens.get(index + 2) else { continue };
        if !bang {
            continue;
        }
        let parsed: MacroArguments = syn::parse2(arguments.stream()).unwrap_or_else(|error| {
            panic!("{file}: t! arguments are not `\"id\", name = expr, ...`: {error}")
        });
        uses.push((
            file.to_owned(),
            parsed.id.value(),
            parsed.names.into_iter().map(|n| n.to_string()).collect(),
        ));
    }
}

/// `"id", name = expr, ...`, parsed with Rust's own expression grammar.
struct MacroArguments {
    id: syn::LitStr,
    names: Vec<syn::Ident>,
}

impl syn::parse::Parse for MacroArguments {
    fn parse(input: syn::parse::ParseStream) -> syn::Result<Self> {
        let id: syn::LitStr = input.parse()?;
        let mut names = Vec::new();
        while !input.is_empty() {
            input.parse::<syn::Token![,]>()?;
            if input.is_empty() {
                break;
            }
            let name: syn::Ident = input.parse()?;
            input.parse::<syn::Token![=]>()?;
            let _value: syn::Expr = input.parse()?;
            names.push(name);
        }
        Ok(Self { id, names })
    }
}

fn walk(root: &Path) -> Vec<std::path::PathBuf> {
    let mut files = Vec::new();
    let mut pending = vec![root.to_path_buf()];
    while let Some(dir) = pending.pop() {
        for entry in std::fs::read_dir(&dir).unwrap().flatten() {
            let path = entry.path();
            if path.is_dir() {
                pending.push(path);
            } else if path.extension().is_some_and(|ext| ext == "rs") {
                files.push(path);
            }
        }
    }
    files.sort();
    files
}

// ----- Plural rules ---------------------------------------------------------

/// The plural-rules locale fluent-bundle would use for this tag: the same
/// lookup it performs, so "en-GB" resolves to "en" and "zh-Hant" to "zh".
/// A language that would silently get English rules is a mistake.
fn plural_rules(tag: &str, pseudo: bool) -> Result<PluralRules, String> {
    let english: LanguageIdentifier = "en".parse().unwrap();
    let available: Vec<LanguageIdentifier> = PluralRules::get_locales(PluralRuleType::CARDINAL)
        .iter()
        .map(|locale| locale.to_string().parse().expect("valid plural-rules locale"))
        .collect();
    let wanted: LanguageIdentifier =
        if pseudo { english.clone() } else { tag.parse().map_err(|e| format!("{e:?}"))? };
    let chosen = negotiate_languages(
        std::slice::from_ref(&wanted),
        &available,
        Some(&english),
        NegotiationStrategy::Lookup,
    )[0]
    .clone();
    if chosen.language != wanted.language {
        return Err(format!(
            "{tag}: no CLDR plural rules for this language; it would silently get English rules"
        ));
    }
    PluralRules::create(
        chosen.to_string().parse::<unic_langid::LanguageIdentifier>().map_err(|e| format!("{e:?}"))?,
        PluralRuleType::CARDINAL,
    )
    .map_err(|error| format!("{tag}: no plural rules: {error:?}"))
}

/// The cardinal categories a language actually uses, found by asking the
/// rules about a spread of integers and fractions.
fn plural_categories(rules: &PluralRules) -> BTreeSet<String> {
    let mut categories = BTreeSet::new();
    for number in 0..=1200 {
        categories.insert(format!("{:?}", rules.select(number as f64).unwrap()).to_lowercase());
    }
    for fraction in [0.5f64, 1.5, 2.5, 10.5] {
        categories.insert(format!("{:?}", rules.select(fraction).unwrap()).to_lowercase());
    }
    categories
}

const CATEGORY_WORDS: [&str; 6] = ["zero", "one", "two", "few", "many", "other"];
const COUNTS: [i64; 12] = [0, 1, 2, 3, 4, 5, 11, 12, 21, 22, 101, 1000];

/// Sample arguments for a message: numbers for selector variables, text for
/// the rest. The text samples are distinctive so their presence in the
/// output can be checked.
fn sample_args(info: &MessageInfo, count: i64) -> Vec<(&str, Arg)> {
    info.variables
        .iter()
        .map(|name| {
            let numeric = info.selectors.contains(name);
            (name.as_str(), if numeric { Arg::Int(count) } else { Arg::Text(format!("<{name}>")) })
        })
        .collect()
}

// ----- Per-catalog validation --------------------------------------------

/// Translations that may legitimately leave out a source variable. Empty
/// today; add `(tag, message id, variable)` with a reason if a language
/// needs it.
const OMISSIONS_ALLOWED: &[(&str, &str, &str)] = &[];

/// Validates one catalog's text on its own against the parsed source. The
/// result lists every problem found; an empty list is a pass.
fn validate(tag: &str, ftl: &str, pseudo: bool, source: &Parsed) -> Vec<String> {
    let is_source = tag == catalog::SOURCE_TAG;
    let overlay = !is_source && tag.starts_with("en-");
    let parsed = match parse_text(tag, ftl) {
        Ok(parsed) => parsed,
        Err(problems) => return problems,
    };
    let mut problems: Vec<String> = reference_problems(tag, &parsed);
    let (bundle, compile_problems) = compile(tag.parse().expect("a valid tag"), ftl, pseudo);
    problems.extend(compile_problems.into_iter().map(|problem| format!("{tag}: {problem}")));
    let categories = match plural_rules(tag, pseudo) {
        Ok(rules) => plural_categories(&rules),
        Err(problem) => {
            problems.push(problem);
            return problems;
        }
    };

    for (id, info) in &source.messages {
        let Some(target) = parsed.messages.get(id) else {
            if !overlay {
                problems.push(format!("{tag}: missing message {id}"));
            }
            continue;
        };
        for variable in target.variables.difference(&info.variables) {
            problems.push(format!("{tag}: {id} uses a variable the source does not have: ${variable}"));
        }
        for variable in info.variables.difference(&target.variables) {
            if !OMISSIONS_ALLOWED.contains(&(tag, id.as_str(), variable.as_str())) {
                problems.push(format!("{tag}: {id} dropped the source variable ${variable}"));
            }
        }
        // A text variable (one the source does not merely select on) must be
        // shown on every branch of the translation, statically.
        for variable in info.variables.difference(&info.selectors) {
            if target.variables.contains(variable)
                && !target.always_shown.contains(variable)
                && !OMISSIONS_ALLOWED.contains(&(tag, id.as_str(), variable.as_str()))
            {
                problems.push(format!("{tag}: {id} does not show ${variable} on every branch"));
            }
        }
        if !target.functions.is_empty() {
            problems.push(format!("{tag}: {id} calls functions {:?}; none are registered", target.functions));
        }
        for (selector, keys) in &target.category_keys {
            for key in keys {
                if CATEGORY_WORDS.contains(&key.as_str()) && !categories.contains(key) {
                    problems.push(format!(
                        "{tag}: {id} selects [{key}] on ${selector}, but {tag} has only {categories:?}"
                    ));
                }
            }
        }
        // Format the translation by itself, with no fallback, for the fixed
        // counts and for every exact numeric variant it declares.
        let Some(message) = bundle.get_message(id) else { continue };
        let Some(pattern) = message.value() else { continue };
        let counts: BTreeSet<i64> =
            COUNTS.iter().copied().chain(target.numeric_keys.iter().copied()).collect();
        for count in counts {
            let args = sample_args(info, count);
            let mut fluent_args = FluentArgs::new();
            for (name, value) in &args {
                fluent_args.set(*name, value.fluent());
            }
            let mut errors = Vec::new();
            let text = bundle.format_pattern(pattern, Some(&fluent_args), &mut errors);
            if !errors.is_empty() {
                problems.push(format!("{tag}: {id} did not format for count {count}: {errors:?}"));
                break;
            }
            for (name, value) in &args {
                if let Arg::Text(sample) = value
                    && !text.contains(sample.as_str())
                {
                    problems
                        .push(format!("{tag}: {id} lost the text of ${name} for count {count}: {text:?}"));
                }
            }
        }
    }
    for id in parsed.messages.keys() {
        if !source.messages.contains_key(id) {
            problems.push(format!("{tag}: message {id} is not in the source catalog"));
        }
    }
    problems
}

/// The playbook messages the built-in manifest calls for: option labels for
/// every option, and a description for every page whose description is not
/// the shared boilerplate. Each needs UI copy and a separate exact-text
/// baseline for the runtime guard.
fn playbook_inventory() -> BTreeMap<String, String> {
    let manifest = crate::services::playbook::Manifest::builtin();
    let mut expected = BTreeMap::new();
    for page in &manifest.pages {
        for option in &page.options {
            expected.insert(format!("playbook-option-{}", option.name), option.text.trim().to_owned());
        }
        let description = page.description.trim();
        if !description.is_empty() && !super::describe::is_page_boilerplate(description) {
            let first = page.options.first().map(|option| option.name.as_str()).unwrap_or_default();
            expected.insert(format!("playbook-page-{first}-description"), description.to_owned());
        }
    }
    expected
}

#[test]
fn catalog_checks_source_covers_every_message_the_app_uses() {
    let source = parse(catalog::source());
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("src");
    let uses = macro_uses(&root);
    assert!(uses.len() > 200, "the scan found only {} t! uses; is the scanner broken?", uses.len());
    let mut used: BTreeSet<&str> = BTreeSet::new();
    for (file, id, args) in &uses {
        let info = source
            .messages
            .get(id)
            .unwrap_or_else(|| panic!("{file}: t!({id:?}) is not in the en-GB catalog"));
        assert_eq!(
            &info.variables, args,
            "{file}: t!({id:?}) passes {args:?} but the message uses {:?}",
            info.variables
        );
        used.insert(id);
    }
    let inventory = playbook_inventory();
    let unused: Vec<&String> = source
        .messages
        .keys()
        .filter(|id| !used.contains(id.as_str()) && !inventory.contains_key(*id))
        .collect();
    assert!(unused.is_empty(), "messages in en-GB that nothing uses: {unused:?}");
    for (id, info) in &source.messages {
        assert!(
            info.functions.is_empty(),
            "{id}: the source uses Fluent functions {:?}; none are registered",
            info.functions
        );
    }
}

#[test]
fn catalog_checks_playbook_text_matches_the_builtin_manifest() {
    let english = catalog::Catalog::new(&[catalog::source()]);
    let inventory = playbook_inventory();
    for (id, text) in &inventory {
        assert!(english.plain(catalog::SOURCE_TAG, id).is_some(), "{id}: missing UI copy");
        assert_eq!(
            super::describe::playbook_source(id),
            Some(text.as_str()),
            "{id}: the guard baseline must carry the manifest's exact text"
        );
    }
    for id in parse(catalog::source()).messages.keys().filter(|id| id.starts_with("playbook-")) {
        assert!(
            inventory.contains_key(id),
            "{id}: no option or page in the built-in manifest uses this message"
        );
    }
}

#[test]
fn catalog_checks_every_language_is_complete_and_formats_on_its_own() {
    let source = parse(catalog::source());
    let mut problems: Vec<String> = Vec::new();
    for locale in LOCALES.iter().filter(|locale| !locale.pseudo) {
        problems.extend(validate(locale.tag, locale.ftl, false, &source));
        if locale.tag != catalog::SOURCE_TAG && !locale.tag.starts_with("en-") {
            problems.extend(untranslated(locale, &source));
        }
    }
    // The pseudo-locale is the source through a transform; it must format too.
    problems.extend(validate(catalog::SOURCE_TAG, catalog::source().ftl, true, &source));
    assert!(problems.is_empty(), "catalog problems:\n{}", problems.join("\n"));
}

/// Proper nouns, shared words ("Options" in French) and pure-placeholder
/// templates legitimately match English; an untranslated file matches on
/// hundreds.
fn untranslated(locale: &'static Locale, source: &Parsed) -> Vec<String> {
    let english = catalog::Catalog::new(&[catalog::source()]);
    let own = catalog::Catalog::new(&[locale]);
    let identical: Vec<&String> = source
        .messages
        .iter()
        .filter(|(id, info)| {
            let args = sample_args(info, 3);
            !id.starts_with("playbook-option-browser-")
                && !matches!(id.as_str(), "app-name" | "home-github" | "home-discord" | "list-separator")
                && own.format(id, None, &args) == english.format(id, None, &args)
        })
        .map(|(id, _)| id)
        .collect();
    if identical.len() > 40 {
        vec![format!("{}: {} messages are identical to English: {identical:?}", locale.tag, identical.len())]
    } else {
        Vec::new()
    }
}

#[test]
fn catalog_checks_plural_rules_exist_for_every_locale() {
    for locale in LOCALES {
        let categories = plural_categories(&plural_rules(locale.tag, locale.pseudo).unwrap());
        assert!(categories.contains("other"), "{}: {categories:?}", locale.tag);
    }
    assert!(plural_categories(&plural_rules("pl", false).unwrap()).contains("few"));
    assert!(plural_categories(&plural_rules("ru", false).unwrap()).contains("many"));
    assert!(!plural_categories(&plural_rules("ja", false).unwrap()).contains("one"));
}

// ----- Mutation tests: the gate must reject these ---------------------------

/// Replaces one message's value (single- or multi-line) in catalog text.
fn mutate(ftl: &str, id: &str, replacement: &str) -> String {
    let mut out = String::new();
    let mut skipping = false;
    let prefix = format!("{id} =");
    for line in ftl.lines() {
        if line.starts_with(&prefix) {
            out.push_str(&format!("{id} = {replacement}\n"));
            skipping = true;
            continue;
        }
        if skipping && line.starts_with(' ') {
            continue;
        }
        skipping = false;
        out.push_str(line);
        out.push('\n');
    }
    assert!(out != ftl, "{id} not found");
    out
}

fn german_problems(mutation: impl FnOnce(&str) -> String) -> Vec<String> {
    let source = parse(catalog::source());
    let german = catalog::find("de").unwrap();
    validate("de", &mutation(german.ftl), false, &source)
}

#[test]
fn the_gate_rejects_a_broken_message_reference() {
    let problems = german_problems(|ftl| mutate(ftl, "common-cancel", "{ nonexistent-reference }"));
    assert!(
        problems.iter().any(|p| p.contains("common-cancel") && p.contains("does not exist")),
        "{problems:?}"
    );
    assert!(
        problems.iter().any(|p| p.contains("common-cancel") && p.contains("did not format")),
        "{problems:?}"
    );
}

#[test]
fn the_gate_rejects_a_broken_reference_hidden_in_an_unsampled_branch() {
    // The recheck's case: a bad reference behind an exact variant no sample hits.
    let problems = german_problems(|ftl| {
        mutate(
            ftl,
            "log-earlier-lines",
            "{ $count ->\n        [7] { nonexistent-reference }\n       *[other] { $count } Zeilen\n    }",
        )
    });
    assert!(
        problems.iter().any(|p| p.contains("log-earlier-lines") && p.contains("does not exist")),
        "{problems:?}"
    );
    assert!(
        problems.iter().any(|p| p.contains("log-earlier-lines") && p.contains("did not format for count 7")),
        "declared numeric variants are sampled too: {problems:?}"
    );
}

#[test]
fn the_gate_rejects_a_dropped_variable_and_one_missing_from_a_branch() {
    let problems = german_problems(|ftl| mutate(ftl, "home-status-update", "Ein Update ist verfügbar."));
    assert!(
        problems.iter().any(|p| p.contains("home-status-update") && p.contains("dropped")),
        "{problems:?}"
    );
    // The recheck's case: $titles present in the default branch only.
    let problems = german_problems(|ftl| {
        mutate(
            ftl,
            "detail-updates-pending",
            "{ $count ->\n        [7] Zuerst { $count } Updates.\n       *[other] Zuerst { $count } Updates: { $titles }.\n    }",
        )
    });
    assert!(
        problems.iter().any(|p| p.contains("detail-updates-pending") && p.contains("on every branch")),
        "{problems:?}"
    );
    // A nested select counts branch by branch too.
    let problems = german_problems(|ftl| {
        mutate(
            ftl,
            "detail-updates-pending",
            "{ $count ->\n        [1] { $count ->\n            [1] Eins: { $titles }\n           *[other] Sonst\n        }\n       *[other] Zuerst { $titles }.\n    }",
        )
    });
    assert!(
        problems.iter().any(|p| p.contains("detail-updates-pending") && p.contains("on every branch")),
        "{problems:?}"
    );
}

#[test]
fn the_gate_rejects_a_reference_cycle() {
    let problems = german_problems(|ftl| {
        let ftl = mutate(ftl, "common-cancel", "{ common-back }");
        mutate(&ftl, "common-back", "{ common-cancel }")
    });
    assert!(problems.iter().any(|p| p.contains("cycle")), "{problems:?}");
    assert!(
        problems.iter().any(|p| p.contains("common-cancel") && p.contains("did not format")),
        "{problems:?}"
    );
}

#[test]
fn the_gate_rejects_a_plural_category_the_language_lacks_and_junk() {
    let source = parse(catalog::source());
    let japanese = catalog::find("ja").unwrap();
    let mutated = mutate(
        japanese.ftl,
        "log-earlier-lines",
        "{ $count ->\n        [few] x\n       *[other] { $count } 行\n    }",
    );
    let problems = validate("ja", &mutated, false, &source);
    assert!(problems.iter().any(|p| p.contains("selects [few]")), "{problems:?}");
    let junk = format!("{}\nthis is not fluent\n", japanese.ftl);
    let problems = validate("ja", &junk, false, &source);
    assert!(problems.iter().any(|p| p.contains("junk")), "{problems:?}");
}

#[test]
fn the_gate_validates_the_source_too() {
    let source = parse(catalog::source());
    let broken = mutate(catalog::source().ftl, "common-cancel", "{ nonexistent-reference }");
    let problems = validate(catalog::SOURCE_TAG, &broken, false, &source);
    assert!(problems.iter().any(|p| p.contains("common-cancel")), "{problems:?}");
}

#[test]
fn the_scanner_reads_every_macro_spelling_and_real_rust_arguments() {
    let sample = r#"
        // t!("in-a-comment")
        /// t!("in-a-doc-comment")
        fn f() {
            let _ = "t!(\"in-a-string\")";
            let a = t!("plain");
            let b = crate::t!("qualified", count = items.len(), name = format!("{a}, {b}", a, b));
            let c = t! { "braced" };
            let d = t! [ "bracketed", x = 1 ];
            let e = t! ("spaced");
            let g = t!("generic", value = make::<A, B>(), other = if a < b { 1 } else { 2 },);
            assert!(true);
        }
    "#;
    let mut uses = Vec::new();
    scan_stream(TokenStream::from_str(sample).unwrap(), "sample.rs", &mut uses);
    let ids: Vec<&str> = uses.iter().map(|(_, id, _)| id.as_str()).collect();
    assert_eq!(ids, ["plain", "qualified", "braced", "bracketed", "spaced", "generic"]);
    assert_eq!(uses[1].2.iter().cloned().collect::<Vec<_>>(), ["count", "name"]);
    assert_eq!(uses[3].2.iter().cloned().collect::<Vec<_>>(), ["x"]);
    assert_eq!(uses[5].2.iter().cloned().collect::<Vec<_>>(), ["other", "value"]);
}
