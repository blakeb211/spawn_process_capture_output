package scratch
// Spawn a program as a separate process and capture its output. 
// Use existing bindings in the core lib if possible.

import "core:fmt"
import "core:os"
import win32 "core:sys/win32"

conv16_to_8 :: win32.utf16_to_utf8;
conv8_to_16 :: win32.utf8_to_utf16;

main :: proc() {
	cmd_line : []u16 = conv8_to_16(`c:\windows\sysWOW64\findstr.exe /s /n process c:\odin-0722\*.odin`);
	fmt.println("\ncmd_line:", conv16_to_8(cmd_line));	
	
	sec_attrib : win32.Security_Attributes;
	proc_attrib : ^win32.Security_Attributes = nil;
	thread_attrib : ^win32.Security_Attributes = nil;


	inh_handle := win32.Bool(false);

	CREATE_NEW_CONSOLE :: u32(0x00000010); // wasn't able to capture stdout with this flag set
	CREATE_UNICODE_ENV :: u32(0x00000400);
	DETACHED_PROCESS ::   u32(0x00000008); // wasn't able to capture stdout with this flag set
	creation_flags := CREATE_UNICODE_ENV;  

	env : rawptr = nil; // use environment of calling process

	sz_curr_dir := win32.get_current_directory_w(0, nil);
	curr_dir := make([]u16, sz_curr_dir, context.temp_allocator);
  win32.get_current_directory_w(sz_curr_dir,win32.Wstring(&curr_dir[0]));

	fmt.println("curr dir:", conv16_to_8(curr_dir));

	//start_info : win32.Startup_Info = {stdout = win32.Handle(os.stdout), stderr = win32.Handle(os.stdout)};
	start_info : win32.Startup_Info = {cb = size_of(win32.Startup_Info), stdout = win32.Handle(os.stdout), stderr = win32.Handle(os.stderr)};

	proc_info : win32.Process_Information;

	result : win32.Bool = win32.create_process_w(	win32.Wstring(nil), win32.Wstring(&cmd_line[0]), proc_attrib, thread_attrib, 
														 									inh_handle, creation_flags, env, win32.Wstring(&curr_dir[0]), &start_info, &proc_info) ;
	if result != win32.Bool(false) { 
		fmt.println("Successfully started new process");
	}
	win32.wait_for_single_object(proc_info.process, 50_000_000);
	win32.close_handle(proc_info.process);
	win32.close_handle(proc_info.thread);
	fmt.println("Calling process ended...");
}

// API NOTES
/* 
	create_process_w             :: proc(application_name, command_line: Wstring,
	                                     process_attributes, thread_attributes: ^Security_Attributes,
	                                     inherit_handle: Bool, creation_flags: u32, environment: rawptr,
	                                     current_direcotry: Wstring, startup_info: ^Startup_Info,
	                                     process_information: ^Process_Information) -> Bool ---;

Security_Attributes :: struct {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

Process_Information :: struct {
	process:    Handle,
	thread:     Handle,
	process_id: u32,
	thread_id:  u32
}

Startup_Info :: struct {
    cb:             u32,
    reserved:       Wstring,
    desktop:        Wstring,
    title:          Wstring,
    x:              u32,
    y:              u32,
    x_size:         u32,
    y_size:         u32,
    x_count_chars:  u32,
    y_count_chars:  u32,
    fill_attribute: u32,
    flags:          u32,
    show_window:    u16,
    _:              u16,
    _:              cstring,
    stdin:          Handle,
    stdout:         Handle,
    stderr:         Handle,
}

*/
