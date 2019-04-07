# Eventcmd

Eventcmd is a command line tool to execute your command when an event occurs on a watched file or directory.
There are several events you can listen for, such as 'modify' occurs in writing a file, while 'create' happens when a file or directory is created.
These events are collected using [inotify-tools](https://github.com/rvoicilas/inotify-tools).
The tool outputs event information and a file or directory name on which event occurs.
The information allows Eventcmd to access various files you watched and execute a user-requested command for them.
Eventcmd is currently used for when watched files are modified.

## Installation

1. Install [inotify-tools](https://github.com/rvoicilas/inotify-tools).
1. Download eventcmd.sh from this repository, change it to your favorite name, and place it in your bin directory. For example,

```bash
wget -O eventcmd https://raw.githubusercontent.com/SausageCats/eventcmd/master/eventcmd.sh
chmod +x eventcmd
mkdir ~/bin
mv eventcmd ~/bin
export PATH=$PATH:~/bin
```

## Usage and Examples

Please enter `eventcmd -h` to learn how to use Eventcmd.

## Note

By default, Eventcmd is implemented that inotifywait can receive multiple events.
However, there is a problem with this implementation when a watching target is a file instead of a directory.
For example, when a watched file is saved, inotifywait outputs 'move_self' or 'delete_self' events.
These events cause inotifywait to stop monitoring the file although it is still present.
This problem occurs in Vim and it might be avoided by receiving a single event.
Therefore, Eventcmd automatically switches to the single event when encountering such a problem.
This is valid only in case user does not listen for specific events with --event option.
In the single event, any event does not occur until after user command is finished.

## Video

Here is an example of automatically executing a python file when saving it in Vim.

![demo](https://github.com/SausageCats/video/raw/master/eventcmd/eventcmd_demo.gif)
