# File:        compile_lib.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Library Compiler: turns one Liberty file (.lib) into the binary .db the Synopsys tools read. Inputs: environment variables LIB_FILE and DB_FILE.

set lib_file $::env(LIB_FILE)   ;# Liberty source
set db_file  $::env(DB_FILE)    ;# .db to write

# library name: the name in `library (<name>)` near the top of the file
set fh [open $lib_file]
set text [read $fh]
close $fh
if {![regexp {library\s*\(\s*"?([^")\s]+)"?\s*\)} $text -> name]} {
    puts "SB-ERROR: no library (...) group in $lib_file"
    exit 1
}

read_lib $lib_file
write_lib $name -format db -output $db_file
puts "SB: $name -> $db_file"
exit
