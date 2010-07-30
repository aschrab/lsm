LSM tools
=========

These are the tools used for maintaining the Linux Software Map.

base directory
--------------

`.cropmail-rules` [cropmail](http://opensource.bertram-scharpf.de/sites/cropmail/)
rules for processing incoming messages.  Responds to requests for entry template,
checks syntax of incoming entries, sends responses, and writes valid entries to
update files for later merging.

`.procmailrc` This was previously used for handling incoming mail.  Doesn't work
well with many MIME messages.

bin
---

`update` zsh shell script that updates contents of the FTP site.

`lsmconv` sed script to convert entries from LSM3 to LSM4 format.

ruby_lsm
--------

Current version of the tools.

`lsm.rb` is the library used for parsing LSM entries and files.
It can also be run as a script to check the syntax of an LSM file.

`apply_updates.rb` merges updates from one or more files to the old LSM file to
produce the updated version.  If run with too few arguments it will output the
necessary syntax.

lsmcheck
--------

Old, C-based tools for working maintaing LSM.  Won't currently compile.

Most of the code is in the liw modules of publib, both of which are included in
a tar file.

<!-- vim: set filetype=markdown : -->
