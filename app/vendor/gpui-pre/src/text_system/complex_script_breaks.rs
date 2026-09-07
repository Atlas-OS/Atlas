//! Break opportunities for scripts omitted by GPUI 0.3.3's word-character list.
//! Other scripts deliberately retain upstream wrapping.

pub(super) struct ComplexBreaks {
    pub opportunities: Vec<usize>,
    pub clusters: Vec<usize>,
}

pub(super) fn for_text(text: &str) -> Option<ComplexBreaks> {
    if !text.chars().any(|ch| matches!(ch, '\u{0900}'..='\u{097f}' | '\u{0e00}'..='\u{0e7f}')) {
        return None;
    }
    Some(ComplexBreaks {
        opportunities: icu_segmenter::LineSegmenter::new_dictionary(Default::default())
            .segment_str(text)
            .collect(),
        clusters: icu_segmenter::GraphemeClusterSegmenter::new().segment_str(text).collect(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hindi_keeps_words_and_combining_marks_together() {
        let text = "अगर अभी जारी नहीं रखना चाहते तो सुरक्षा सुविधाएँ फिर चालू करें।";
        let breaks = for_text(text).unwrap();
        for word in ["अगर", "सुरक्षा", "सुविधाएँ"] {
            let start = text.find(word).unwrap();
            assert!(!breaks.opportunities.iter().any(|&i| i > start && i < start + word.len()));
        }
        assert!(breaks.opportunities.iter().all(|i| breaks.clusters.contains(i)));
        assert!(breaks.opportunities.len() > 4);
    }

    #[test]
    fn thai_uses_dictionary_boundaries_instead_of_character_boundaries() {
        let text = "การติดตั้งหยุดลงและอาจมีการเปลี่ยนแปลงบางอย่างแล้ว";
        let breaks = for_text(text).unwrap();
        // A dictionary may split a compound at its component words, but must
        // never split these syllables as the old per-character wrapper did.
        for word in ["ติด", "ตั้ง"] {
            let start = text.find(word).unwrap();
            assert!(!breaks.opportunities.iter().any(|&i| i > start && i < start + word.len()));
        }
        assert!(breaks.opportunities.len() > 3);
        assert!(breaks.opportunities.len() < text.chars().count());
        assert!(breaks.opportunities.iter().all(|i| breaks.clusters.contains(i)));
    }

    #[test]
    fn existing_scripts_keep_upstream_wrapping() {
        for text in ["Hello world", "Ändern", "Русский", "日本語", "繁體中文", "Bahasa Indonesia"]
        {
            assert!(for_text(text).is_none());
        }
    }
}
