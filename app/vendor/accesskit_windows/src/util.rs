// Copyright 2022 The AccessKit Authors. All rights reserved.
// Licensed under the Apache License, Version 2.0 (found in
// the LICENSE-APACHE file) or the MIT license (found in
// the LICENSE-MIT file), at your option.

use accesskit::{Color, Point, TextAlign, TextDecorationStyle};
use accesskit_consumer::{TextRangePropertyValue, TreeState};
use std::{
    cell::RefCell,
    fmt::{self, Write},
    mem::ManuallyDrop,
    ops::{Deref, DerefMut},
    sync::{Arc, Weak},
};
use windows::{
    Win32::{
        Foundation::*,
        Globalization::*,
        Graphics::Gdi::*,
        System::{Com::*, Ole::*, Variant::*},
        UI::{Accessibility::*, WindowsAndMessaging::*},
    },
    core::*,
};

use crate::window_handle::WindowHandle;

thread_local! {
    static STRING_SCRATCH: RefCell<Vec<Vec<u16>>> = const { RefCell::new(Vec::new()) };
}

const MAX_RETAINED_SCRATCH_CAPACITY: usize = 4096;
const MAX_POOLED_BUFFERS: usize = 2;

/// A scratch buffer for wide-string conversion, leased from a thread-local pool.
pub(crate) struct StringBuffer(Vec<u16>);

impl StringBuffer {
    pub(crate) fn acquire() -> Self {
        Self(STRING_SCRATCH.with(|c| c.borrow_mut().pop().unwrap_or_default()))
    }
}

impl Drop for StringBuffer {
    fn drop(&mut self) {
        let mut buf = std::mem::take(&mut self.0);
        if buf.capacity() > MAX_RETAINED_SCRATCH_CAPACITY {
            buf.clear();
            buf.shrink_to(MAX_RETAINED_SCRATCH_CAPACITY);
        }
        STRING_SCRATCH.with(|c| {
            let mut pool = c.borrow_mut();
            if pool.len() < MAX_POOLED_BUFFERS {
                pool.push(buf);
            }
        });
    }
}

impl Deref for StringBuffer {
    type Target = Vec<u16>;
    fn deref(&self) -> &Vec<u16> {
        &self.0
    }
}

impl DerefMut for StringBuffer {
    fn deref_mut(&mut self) -> &mut Vec<u16> {
        &mut self.0
    }
}

pub(crate) struct WideString<'a>(&'a mut Vec<u16>);

impl<'a> WideString<'a> {
    pub(crate) fn new(buffer: &'a mut Vec<u16>) -> Self {
        buffer.clear();
        Self(buffer)
    }
}

impl Write for WideString<'_> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.0.extend(s.encode_utf16());
        Ok(())
    }

    fn write_char(&mut self, c: char) -> fmt::Result {
        self.0.extend_from_slice(c.encode_utf16(&mut [0; 2]));
        Ok(())
    }
}

impl PartialEq for WideString<'_> {
    fn eq(&self, other: &Self) -> bool {
        *self.0 == *other.0
    }
}

impl From<WideString<'_>> for BSTR {
    fn from(value: WideString) -> Self {
        Self::from_wide(value.0)
    }
}

#[derive(Debug, PartialEq, Eq)]
pub(crate) struct LocaleName<'a>(pub(crate) &'a str);

impl From<LocaleName<'_>> for Variant {
    fn from(value: LocaleName) -> Self {
        let lcid = unsafe { LocaleNameToLCID(&HSTRING::from(value.0), LOCALE_ALLOW_NEUTRAL_NAMES) };
        (lcid != 0).then_some(lcid as i32).into()
    }
}

pub(crate) struct Variant(VARIANT);

impl From<Variant> for VARIANT {
    fn from(variant: Variant) -> Self {
        variant.0
    }
}

impl Variant {
    pub(crate) fn empty() -> Self {
        Self(VARIANT::default())
    }

    pub(crate) fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl From<BSTR> for Variant {
    fn from(value: BSTR) -> Self {
        Self(value.into())
    }
}

impl From<WideString<'_>> for Variant {
    fn from(value: WideString) -> Self {
        BSTR::from(value).into()
    }
}

#[derive(Debug)]
pub(crate) struct StrWrapper<'a> {
    value: &'a str,
    buffer: &'a mut Vec<u16>,
}

impl<'a> StrWrapper<'a> {
    pub(crate) fn new(value: &'a str, buffer: &'a mut Vec<u16>) -> Self {
        Self { value, buffer }
    }
}

impl PartialEq for StrWrapper<'_> {
    fn eq(&self, other: &Self) -> bool {
        self.value == other.value
    }
}

impl From<StrWrapper<'_>> for Variant {
    fn from(w: StrWrapper) -> Self {
        let mut result = WideString::new(w.buffer);
        result.write_str(w.value).unwrap();
        result.into()
    }
}

impl From<IUnknown> for Variant {
    fn from(value: IUnknown) -> Self {
        Self(value.into())
    }
}

impl From<i32> for Variant {
    fn from(value: i32) -> Self {
        Self(value.into())
    }
}

impl From<f64> for Variant {
    fn from(value: f64) -> Self {
        Self(value.into())
    }
}

impl From<ToggleState> for Variant {
    fn from(value: ToggleState) -> Self {
        Self(value.0.into())
    }
}

impl From<ExpandCollapseState> for Variant {
    fn from(value: ExpandCollapseState) -> Self {
        Self(value.0.into())
    }
}

impl From<LiveSetting> for Variant {
    fn from(value: LiveSetting) -> Self {
        Self(value.0.into())
    }
}

impl From<CaretPosition> for Variant {
    fn from(value: CaretPosition) -> Self {
        Self(value.0.into())
    }
}

impl From<UIA_CONTROLTYPE_ID> for Variant {
    fn from(value: UIA_CONTROLTYPE_ID) -> Self {
        Self(value.0.into())
    }
}

impl From<OrientationType> for Variant {
    fn from(value: OrientationType) -> Self {
        Self(value.0.into())
    }
}

impl From<Color> for Variant {
    fn from(value: Color) -> Self {
        let rgb: i32 =
            (value.red as i32) | ((value.green as i32) << 8) | ((value.blue as i32) << 16);
        Self(rgb.into())
    }
}

impl From<TextDecorationStyle> for Variant {
    fn from(value: TextDecorationStyle) -> Self {
        let value = match value {
            TextDecorationStyle::Solid => TextDecorationLineStyle_Single,
            TextDecorationStyle::Dotted => TextDecorationLineStyle_Dot,
            TextDecorationStyle::Dashed => TextDecorationLineStyle_Dash,
            TextDecorationStyle::Double => TextDecorationLineStyle_Double,
            TextDecorationStyle::Wavy => TextDecorationLineStyle_Wavy,
        };
        Self::from(value.0)
    }
}

impl From<TextAlign> for Variant {
    fn from(value: TextAlign) -> Self {
        let value = match value {
            TextAlign::Left => HorizontalTextAlignment_Left,
            TextAlign::Right => HorizontalTextAlignment_Right,
            TextAlign::Center => HorizontalTextAlignment_Centered,
            TextAlign::Justify => HorizontalTextAlignment_Justified,
        };
        Self::from(value.0)
    }
}

impl From<bool> for Variant {
    fn from(value: bool) -> Self {
        Self(value.into())
    }
}

impl<T: Into<Variant>> From<Option<T>> for Variant {
    fn from(value: Option<T>) -> Self {
        value.map_or_else(Self::empty, T::into)
    }
}

impl<T: Into<Variant> + std::fmt::Debug + PartialEq> From<TextRangePropertyValue<T>> for Variant {
    fn from(value: TextRangePropertyValue<T>) -> Self {
        match value {
            TextRangePropertyValue::Single(value) => value.into(),
            TextRangePropertyValue::Mixed => unsafe { UiaGetReservedMixedAttributeValue() }
                .unwrap()
                .into(),
        }
    }
}

impl From<Vec<IUnknown>> for Variant {
    fn from(value: Vec<IUnknown>) -> Self {
        if value.is_empty() {
            Variant::empty()
        } else {
            let parray = safe_array_from_com_slice(&value);
            Self(VARIANT {
                Anonymous: VARIANT_0 {
                    Anonymous: ManuallyDrop::new(VARIANT_0_0 {
                        vt: VT_ARRAY | VT_UNKNOWN,
                        wReserved1: 0,
                        wReserved2: 0,
                        wReserved3: 0,
                        Anonymous: VARIANT_0_0_0 { parray },
                    }),
                },
            })
        }
    }
}

fn safe_array_from_primitive_slice<T>(vt: VARENUM, slice: &[T]) -> *mut SAFEARRAY {
    let sa = unsafe { SafeArrayCreateVector(VARENUM(vt.0), 0, slice.len().try_into().unwrap()) };
    if sa.is_null() {
        panic!("SAFEARRAY allocation failed");
    }
    for (i, item) in slice.iter().enumerate() {
        let i: i32 = i.try_into().unwrap();
        unsafe { SafeArrayPutElement(&*sa, &i, (item as *const T) as *const _) }.unwrap();
    }
    sa
}

pub(crate) fn safe_array_from_i32_slice(slice: &[i32]) -> *mut SAFEARRAY {
    safe_array_from_primitive_slice(VT_I4, slice)
}

pub(crate) fn safe_array_from_f64_slice(slice: &[f64]) -> *mut SAFEARRAY {
    safe_array_from_primitive_slice(VT_R8, slice)
}

pub(crate) fn safe_array_from_com_slice(slice: &[IUnknown]) -> *mut SAFEARRAY {
    let sa = unsafe { SafeArrayCreateVector(VT_UNKNOWN, 0, slice.len().try_into().unwrap()) };
    if sa.is_null() {
        panic!("SAFEARRAY allocation failed");
    }
    for (i, item) in slice.iter().enumerate() {
        let i: i32 = i.try_into().unwrap();
        unsafe { SafeArrayPutElement(&*sa, &i, std::mem::transmute_copy(item)) }.unwrap();
    }
    sa
}

pub(crate) enum QueuedEvent {
    Simple {
        element: IRawElementProviderSimple,
        event_id: UIA_EVENT_ID,
    },
    PropertyChanged {
        element: IRawElementProviderSimple,
        property_id: UIA_PROPERTY_ID,
        old_value: VARIANT,
        new_value: VARIANT,
    },
}

pub(crate) fn not_implemented() -> Error {
    E_NOTIMPL.into()
}

pub(crate) fn invalid_arg() -> Error {
    E_INVALIDARG.into()
}

pub(crate) fn required_param<'a, T: Interface>(param: &'a Ref<T>) -> Result<&'a T> {
    param.ok().map_err(|_| invalid_arg())
}

pub(crate) fn element_not_available() -> Error {
    HRESULT(UIA_E_ELEMENTNOTAVAILABLE as _).into()
}

pub(crate) fn element_not_enabled() -> Error {
    HRESULT(UIA_E_ELEMENTNOTENABLED as _).into()
}

pub(crate) fn invalid_operation() -> Error {
    HRESULT(UIA_E_INVALIDOPERATION as _).into()
}

pub(crate) fn not_supported() -> Error {
    HRESULT(UIA_E_NOTSUPPORTED as _).into()
}

pub(crate) fn client_top_left(hwnd: WindowHandle) -> Point {
    let mut result = POINT::default();
    // If ClientToScreen fails, that means the window is gone.
    // That's an unexpected condition, so we should fail loudly.
    unsafe { ClientToScreen(hwnd.0, &mut result) }.unwrap();
    Point::new(result.x.into(), result.y.into())
}

pub(crate) fn window_title(hwnd: WindowHandle, buffer: &mut Vec<u16>) -> Option<BSTR> {
    // The following is an old hack to get the window caption without ever
    // sending messages to the window itself, even if the window is in
    // the same process but possibly a separate thread. This prevents
    // possible hangs and sluggishness. This hack has been proven to work
    // over nearly 20 years on every version of Windows back to XP.
    let result = unsafe { DefWindowProcW(hwnd.0, WM_GETTEXTLENGTH, WPARAM(0), LPARAM(0)) };
    if result.0 <= 0 {
        return None;
    }
    let capacity = (result.0 as usize) + 1; // make room for the null
    buffer.clear();
    buffer.reserve(capacity);
    let result = unsafe {
        DefWindowProcW(
            hwnd.0,
            WM_GETTEXT,
            WPARAM(capacity),
            LPARAM(buffer.as_mut_ptr() as _),
        )
    };
    if result.0 <= 0 {
        return None;
    }
    let len = result.0 as usize;
    unsafe { buffer.set_len(len) };
    Some(BSTR::from_wide(buffer))
}

pub(crate) fn toolkit_description<'a>(
    state: &TreeState,
    buffer: &'a mut Vec<u16>,
) -> WideString<'a> {
    let mut result = WideString::new(buffer);
    result.write_str(state.toolkit_name()).unwrap();
    if let Some(version) = state.toolkit_version() {
        result.write_char(' ').unwrap();
        result.write_str(version).unwrap();
    }
    result
}

pub(crate) fn upgrade<T>(weak: &Weak<T>) -> Result<Arc<T>> {
    match weak.upgrade() {
        Some(strong) => Ok(strong),
        _ => Err(element_not_available()),
    }
}

pub(crate) struct AriaProperties<W: Write> {
    inner: W,
    need_separator: bool,
}

impl<W: Write> AriaProperties<W> {
    pub(crate) fn new(inner: W) -> Self {
        Self {
            inner,
            need_separator: false,
        }
    }

    pub(crate) fn write_property(&mut self, name: &str, value: &str) -> fmt::Result {
        if self.need_separator {
            self.inner.write_char(';')?;
        }
        self.inner.write_str(name)?;
        self.inner.write_char('=')?;
        self.inner.write_str(value)?;
        self.need_separator = true;
        Ok(())
    }

    pub(crate) fn write_bool_property(&mut self, name: &str, value: bool) -> fmt::Result {
        self.write_property(name, if value { "true" } else { "false" })
    }

    pub(crate) fn write_usize_property(&mut self, name: &str, value: usize) -> fmt::Result {
        self.write_property(name, &value.to_string())
    }

    pub(crate) fn has_properties(&self) -> bool {
        self.need_separator
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn on_fresh_thread(f: impl FnOnce() + Send + 'static) {
        std::thread::spawn(f).join().unwrap();
    }

    #[test]
    fn acquire_reuses_dropped_allocation() {
        on_fresh_thread(|| {
            let ptr = {
                let mut buf = StringBuffer::acquire();
                buf.extend(std::iter::repeat_n(0u16, 64));
                buf.as_ptr()
            };
            let buf = StringBuffer::acquire();
            assert_eq!(buf.as_ptr(), ptr);
            assert!(buf.capacity() >= 64);
        });
    }

    #[test]
    fn simultaneous_leases_are_distinct() {
        on_fresh_thread(|| {
            let mut a = StringBuffer::acquire();
            let mut b = StringBuffer::acquire();
            a.push(1);
            b.push(2);
            assert_ne!(a.as_ptr(), b.as_ptr());
            assert_eq!(a[0], 1);
            assert_eq!(b[0], 2);
        });
    }

    #[test]
    fn outsized_allocation_is_released_on_drop() {
        on_fresh_thread(|| {
            {
                let mut buf = StringBuffer::acquire();
                buf.reserve(MAX_RETAINED_SCRATCH_CAPACITY * 4);
                assert!(buf.capacity() > MAX_RETAINED_SCRATCH_CAPACITY);
            }
            let buf = StringBuffer::acquire();
            assert!(buf.capacity() <= MAX_RETAINED_SCRATCH_CAPACITY);
        });
    }

    #[test]
    fn pool_retains_at_most_max_pooled_buffers() {
        on_fresh_thread(|| {
            let bufs: Vec<_> = (0..MAX_POOLED_BUFFERS + 1)
                .map(|_| {
                    let mut buf = StringBuffer::acquire();
                    buf.reserve(64);
                    buf
                })
                .collect();
            drop(bufs);
            let reacquired: Vec<_> = (0..MAX_POOLED_BUFFERS + 1)
                .map(|_| StringBuffer::acquire())
                .collect();
            let reused = reacquired.iter().filter(|buf| buf.capacity() >= 64).count();
            assert_eq!(reused, MAX_POOLED_BUFFERS);
        });
    }
}
