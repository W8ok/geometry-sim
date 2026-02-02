use std::ffi::CString;
use std::os::raw::c_char;

#[unsafe(no_mangle)]
pub extern "C" fn rust_hello() -> *const c_char {
    // Create a C-compatible string
    let s = CString::new("hello from rust").unwrap();

    // Leak it so C can read it safely
    s.into_raw()
}

