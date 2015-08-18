This ARM cross compiler tool chain generate script.

It is necessary makeinfo command and some tools.
Please insall texinfo.
>yum install texinfo

After install texinfo,

git pull
./shell/create_cross_env.bash

This intallation script is using.
GNU binutils-2.25
GNU gcc-5.2.0
GNU glibc-2.20
Linux Kernel Header 4.1.6

It is possible to change another version, channging variable in create_cross_env.bash.
I cannot do generate cross compile enviroment gcc-4.9.x.
