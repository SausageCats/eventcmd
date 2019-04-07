#!/bin/bash


#
# eventcmd configs
#
clear_screen=false
disable_event_for=2
eventverb=true
strict_exclude=
strict_include=
out_format="[Trigger] %e %w\\n[Command] %c"
print_date=false
verbose=true
debug=false
#shopt -s globstar  # if set (shopt -s), '**' finds all files
#
#strict_exclude='\.swp[x]*$|\.swx$|~$|4913$|\.git$|\.o$'
#out_format="[Inotify] %i\\n[Trigger] %e %w\\n[Command] %c"


#
# inotifywait configs
#
inofy_events=delete_self,move_self,modify
inofy_exclude='(~|4913)$|\.(swp[x]*|swx|git|o)$'
inofy_include=
inofy_monitor=true
inofy_quiet=true
inofy_recur=false
#inofy_timeout=-1
inofy_watchfiles=.
#
#inofy_events=attrib,close_write,create,modify


#
# color configs
#
echo_red    () { tput setaf 9 ; echo "$@"; tput sgr0; }
echo_green  () { tput setaf 10; echo "$@"; tput sgr0; }
echo_yellow () { tput setaf 3 ; echo "$@"; tput sgr0; }
echo_cyan   () { tput setaf 44; echo "$@"; tput sgr0; }
#echo_blue   () { tput setaf 12; echo "$@"; tput sgr0; }
#echo_purple () { tput setaf 5 ; echo "$@"; tput sgr0; }



#
# env
#
# env {{{
[[ $EVENTCMD_DEBUG ]] && debug=true
#  }}}


#
# global functions
#
# print_usage {{{
print_usage () {
#    Ex5) -c 'if [[ %e = py ]]; then python2 %f; elif [[ %e = py3 ]]; then python3 %f; else echo nothing; fi'
  usage=$(cat << EOF
Usage: $0 [OPTIONS] <COMMAND> - [FILES|DIRS]
<COMMAND> is a user command that will be executed when a file is modified on watched files or directories.
[FILES|DIRS] is a set of multiple files or directories to be watched.
It is set to '$inofy_watchfiles' as default; the current directory is watched (not contain subdirectory).
NOTE: <COMMAND> and [FILES|DIRS] can be also given using -c and -f options.

Options:
-c <COMMAND>
    Specify a user command; this is the same as <COMMAND> described in 'Usage:'.
    The following conversions are available.
    %b: the base name of a watched file or directory.
    %d: a directory path where a watched file or directory resides.
    %e: the extension of a watched file.
    %f: a watched file path.
    %p: the prefix of a watched file.
    %x: exit \$?
    Ex1) -c 'g++ %f -o a.out && a.out'  # create an executable file in the current directory and run it
    Ex2) -c 'cd %d && g++ -c %b'        # create an object file in %d
    Ex3) -c 'g++ %d/%p.cpp -o %d/%p.o'  # same as above
    Ex4) -c '[[ %e = py ]] && { python2 %f; %x; } || [[ %e = py3 ]] && { python3 %f; %x; } || echo nothing'
-C, --clear
    Clear the screen before <COMMAND> is executed.
-d, --disable <SECONDS>
    Disable multiple events that occurs simultaneously on the same file for <SECONDS> seconds.
    The function is ignored by setting it to zero.
    Ex) -d $disable_event_for  # default
-D, --date
    Print date before <COMMAND> is executed.
-e <PATTERN>, --exclude <PATTERN>
    This is the same as inotifywait --exclude <pattern>.
    An event does not occur on files or directories matching <PATTERN>.
    NOTE1: Both --exclude and --include cannot be specified; if --exclude set, --include is ignored.
    NOTE2: <PATTERN> is an extended regular expression.
    NOTE3: If the first letter of <PATTERN> is '+', the remaining letters are added to the existing exclude pattern.
    Ex1) -e '$inofy_exclude'  # default
    Ex2) -e '+|a.out$'  # this results in -e '$inofy_exclude|a.out$'
-E <PATTERN>
    <COMMAND> will not be executed when watched files or directories match <PATTERN>.
    This is used when filtering files or directories assigned by --exclude or --include options.
    NOTE: <PATTERN> meets NOTE2-3 in --exclude option.
--event <EVENT1,EVENT2,...>
    This is the same as inotifywait --event <event>.
    For more information, enter 'inotifywait -h' or 'man inotifywait'
    Ex1) --event ''               # listen for all events
    Ex2) --event 'create,modify'  # listen for two events separated by comma
    Ex3) --event '$inofy_events'  # default
-F <FORMAT>, --format <FORMAT>
    Print the output of inotifywait before <COMMAND> is executed.
    The following conversions are available.
    %c : a user command.
    %i : an inotifywait command.
    %e : an event that occurred.
    %w : a watched file or directory on which an event occurred.
    Ex1) -F '[Inotify] %i\\\n[Trigger] %e %w\\\n[Command] %c'
    Ex2) -F '${out_format//\\/\\\\}'  # default
-h, --help
    Print this help and exit.
-i <PATTERN>, --include <PATTERN>
    This is the same as inotifywait --include <pattern>.
    An event is triggered by only files or directories matching <PATTERN>.
    NOTE: <PATTERN> meets NOTE1-3 in --exclude option.
    Ex) -i '\.(cpp|py)$'  # matches cpp or py extension
-I <PATTERN>
    <COMMAND> will be executed only when watched files or directories match <PATTERN>.
    This is used when filtering files or directories assigned by --exclude or --include options.
    NOTE: <PATTERN> meets NOTE2-3 in --exclude option.
    Ex) -I '\.(cpp|py)$'  # matches cpp or py extension
-q, --quiet
    Quiet mode (turn verbose off).
-Q
    Quiet mode, but inotifywait output is printed.
-r, --recursive
    Watch directories recursively.
-s <TYPE1,TYPE2,...>, --skip <TYPE1,TYPE2,...>
    Skip <COMMAND> when a watched file or directory is the specified <TYPE>: dir, empty, nonempty, and file.
    They indicate a directory, an empty file, an non-empty file, and a file respectively.
    This option is only limited to 'create' event happened.
    Ex) -s 'dir,empty'  # matches directory or empty file
--single
    Inotifywait receives a single event instead of multiple events.
-t <SECONDS>, --timeout <SECONDS>
    This is the same as inotifywait --timeout <seconds>.
    Unlike inotifywait, a positive number is acceptable.
--test
    Just test for inotifywait events.
-w <FILES|DIRS>
    Specify files or directories to be watched; this is the same as [FILES|DIRS] described in 'Usage:'.
    Ex) -w '$inofy_watchfiles'  # default (the current directory is watched)

Examples:
[1] The following command executes .cpp files in the current directory and the subdirectory (with -r):
    $0 -c 'g++ -Ofast -std=c++17 %f && a.out && rm a.out' -i '\.cpp$' -r
[2] However, if a new directory is created, a file in that directory cannot be watched unless the directory name matches .cpp.
    This can be avoided by using -I option (not -i):
    $0 -c 'g++ -Ofast -std=c++17 %f && a.out && rm a.out' -I '\.cpp$' -r
[3] Without -i or -I options, all files and directories are watched including newly created ones.
    This causes an executable file (a.out) to be watched.
    Therefore the executable file triggers an event to execute a command.
    This can be avoided by using -e '+|a.out' option:
    $0 -c 'g++ -Ofast -std=c++17 %f && a.out && rm a.out' -e '+|a.out' -r
[4] When you want to execute multiple files such as .py and .cpp,  '%e' and '%x' (an extension and exit command) may be useful:
    $0 -c '[[ %e = cpp ]] && { g++ -Ofast -std=c++17 %f && a.out && rm a.out; %x; } || [[ %e = py ]] && { python3 %f; %x; }' -i '\.(cpp|py)$' -r
    $0 -c '[[ %e = cpp ]] && { g++ -Ofast -std=c++17 %f && a.out && rm a.out; %x; } || [[ %e = py ]] && { python3 %f; %x; }' -I '\.(cpp|py)$' -r
    $0 -c '[[ %e = cpp ]] && { g++ -Ofast -std=c++17 %f && a.out && rm a.out; %x; } || [[ %e = py ]] && { python3 %f; %x; } || echo nothing' -e '+|a.out' -r
[5] These commands are long and for readability, it may be better to pass a watched information to a shell script through argument:
    $0 -c './userscript.sh %f %e' -r
EOF
)
c1='\\e[36m\1\\e[m'
g1='\\e[32m\1\\e[m'
r2='\\e[31m\2\\e[m'
y1='\\e[33m\1\\e[m'
usage=$(echo "$usage" | \
          sed -e "s/^\(-.*\)$/$y1/" \
              -e "s/^\(\s\+Ex.*\)$/$c1/" \
              -e "1s/^\(Usage:\s*\)\(.*\)$/$g1$r2/" \
              -e "s/^\(Options:\|Examples:\)/$g1/" \
              -e "s|^\( \+[^ ]\+ -c .\+\)$|$c1|" \
       )
echo -e "$usage"
}
#  }}}
# print_nowdate {{{
print_nowdate () {
  echo_cyan "[$(date '+%Y/%m/%d %H:%M:%S')]"
#  tput setaf 6
#  echo =======================
#  echo "| $(date '+%Y/%m/%d %H:%M:%S') |"
#  echo =======================
#  tput sgr0
}
#  }}}
# inotify_error {{{
inotify_error () {
  [[ $inofy_out ]] \
    && echo_red "$inofy_out" \
    || echo_red "$0: Get an unknown error"
  exit 1
}
#  }}}
# search_inotifypid {{{
search_inotifypid () {
  local pid
  local ppid=$1
  for pid in $(pgrep -P $ppid); do
    kill -0 $pid 2>/dev/null || continue
    ps -h -o pid,command $pid | grep inotifywait > /dev/null && echo $pid
    search_inotifypid $pid
  done
}
#  }}}


#
# parse command line
#
# option analysis {{{
opt_error() {
  echo $0: Option with no value -- $1
  exit 1
}
opt_strictchk() { [[ $2 =~ ^-+ || -z $2 ]] && opt_error "$1"; }
opt_loosechk()  { [[ $2 =~ ^-+          ]] && opt_error "$1"; }


sgl_opt=[CDhqQr]
declare -a args=()
for arg in "$@"; do
  case $arg in
    -*)
      if [[ $1 =~ -$sgl_opt$sgl_opt+$ ]]; then
        splitopt=$(echo ${1:1}|sed -e 's/\(.\)/-\1 /g')
        args=("${args[@]}" $splitopt)  # unnecessary double-quotation mark outside splitopt
      else
        args=("${args[@]}" "$1")
      fi
      shift
      ;;
    *)
      args=("${args[@]}" "$1")
      shift
      ;;
  esac
done
#for arg in "${args[@]}"; do echo -- "$arg"; done


# HACK: put help option here because some default variables are not changed.
#       they are used in print_usage function.
set -- "${args[@]}"
for arg in "${args[@]}"; do
  case $arg in
    -h|--help)
      print_usage
      exit
  esac
done


[[ $inofy_exclude ]] && inofy_pattern_type=exclude
[[ $inofy_include ]] && inofy_pattern_type=include
skip_create_event=false
is_defaultevent=true
is_singleevent=false
for arg in "${args[@]}"; do
#  echo "arg:$arg     \$1:$1"
  case $arg in
    -c)
      opt_strictchk "$1" "$2"
      user_cmd=$2
      shift 2
      use_optcmd=true
      ;;
    -C|--clear)
      clear_screen=true
      shift
      ;;
    -d|--disable)
      opt_strictchk "$1" "$2"
      disable_event_for=$2
      shift 2
      ;;
    -D|--date)
      print_date=true
      shift
      ;;
    -e|--exclude)
      opt_loosechk "$1" "$2"
      [[ ${2:0:1} = + ]] && inofy_exclude+=${2:1} \
                         || inofy_exclude=$2
      inofy_pattern_type=exclude
      shift 2
      ;;
    -E)
      opt_loosechk "$1" "$2"
      [[ ${2:0:1} = + ]] && strict_exclude+=${2:1} \
                         || strict_exclude=$2
      shift 2
      ;;
    --event)
      opt_loosechk "$1" "$2"
      inofy_events=$2
      is_defaultevent=false
      shift 2
      ;;
    -F|--format)
      opt_loosechk "$1" "$2"
      out_format=$2
      shift 2
      ;;
#    -h|--help)
#      print_usage
#      exit
#      ;;
    -i|--include)
      opt_loosechk "$1" "$2"
      [[ ${2:0:1} = + ]] && inofy_include+=${2:1} \
                         || inofy_include=$2
      inofy_pattern_type=include
      shift 2
      ;;
    -I)
      opt_loosechk "$1" "$2"
      [[ ${2:0:1} = + ]] && strict_include+=${2:1} \
                         || strict_include=$2
      shift 2
      ;;
    -q|--quiet)
      verbose=false
      eventverb=false
      shift
      ;;
    -Q)
      verbose=false
      eventverb=true
      shift
      ;;
    -r|--recursive)
      inofy_recur=true
      shift
      ;;
    -s|--skip)
      opt_strictchk "$1" "$2"
      $skip_create_event || {
        skip_create_dir=false
        skip_create_empty=false
        skip_create_nonempty=false
        skip_create_file=false
      }
      skip_create_event=true
      for key in ${2//,/ }; do
        case $key in
          dir)      skip_create_dir=true      ;;
          empty)    skip_create_empty=true    ;;
          nonempty) skip_create_nonempty=true ;;
          file)     skip_create_file=true     ;;
          *) echo_red "Available $1 values: dir, empty, nonempty, and file"; exit 1;;
        esac
      done
      shift 2
      ;;
    --single)
      is_singleevent=true
      shift 1
      ;;
    -t|--timeout)
      opt_strictchk "$1" "$2"
      inofy_timeout=$2
      shift 2
      ;;
    --test)
      inofytest=true
      shift
      ;;
    -w)
      opt_strictchk "$1" "$2"
      inofy_watchfiles=$2
      shift 2
      ;;
    --|-)
      shift
      inofy_watchfiles=$@
      break
      ;;
    -*)
      echo $0: Illegal option -- $1
      exit 1
      ;;
    *)
      if [[ ! -z $1 && ! $1 =~ ^-+ ]]; then
        tmp_usercmd+=("$1")
        shift
        use_optcmd=false
      fi
      ;;
  esac
done
[[ $tmp_usercmd && $use_optcmd = false ]] && user_cmd=${tmp_usercmd[@]}

#if [[ $inofy_watchfiles ]]; then
#  shopt -s globstar
#  inofy_watchfiles=${wfiles[@]}
#echo ${wfiles[@]}
#echo "$inofy_watchfiles"

#  }}}
# error check {{{
#
# FIXME: some error occurs if a wrong option is given.
#        it should be checked here.
#
[[ $user_cmd || $inofytest ]] || { echo_red "Specify user command"; exit 1; }
[[ $inofy_watchfiles ]] || { echo_red "Specify watched files"; exit 1; }
#[[ $inofy_exclude && $inofy_include ]] && { echo_red "Cannot specify both exclude and include"; exit 1; }
#  }}}


#
# make inotifywait comand
#
# make inotifywait command {{{

[[ $inofy_events ]] && inofy_events="--event $inofy_events"
inofy_format="--format '%T|%e|%w%f' --timefmt '%Y_%m_%d_%H_%M_%S'"
inofy_format="--format '%T|%e|%w%f' --timefmt '%s'"
$inofy_monitor && inofy_monitor=-m || inofy_monitor=
$inofy_quiet   && inofy_quiet=-q   || inofy_quiet=
$inofy_recur   && inofy_recur=-r   || inofy_recur=
[[ $inofy_timeout ]] && inofy_timeout="-t $inofy_timeout"
[[ $inofy_pattern_type = exclude ]] && inofy_pats="--exclude '$inofy_exclude'"
[[ $inofy_pattern_type = include ]] && inofy_pats="--include '$inofy_include'"
inofy_cmd="inotifywait $inofy_monitor $inofy_events $inofy_format $inofy_quiet $inofy_recur $inofy_timeout $inofy_pats $inofy_watchfiles"
#  }}}
# print inotifywait and user commands {{{
print_inotifywait_and_user_commands () {
  $print_date && print_nowdate
  $verbose && {
    echo_cyan -n '[Inotifywait]  '
    echo_yellow $inofy_cmd  # remove quotes to see clearly
  }
  $verbose && {
    echo_cyan -n '[User command] '
    echo_yellow "$user_cmd"
  }
}
$clear_screen && clear
print_inotifywait_and_user_commands
#$verbose && { echo_cyan [Loop]; }
#  }}}


#
# Test for inotifywait events
#
# inotifywait test {{{
if [[ $inofytest ]]; then
  $verbose && { echo_cyan [Test for inotifywait events]; }
  i_event=0
  out_pdate=0
  eval "$inofy_cmd" | while read inofy_out; do
    out_date=${inofy_out/%|*}
    out_diffdate=$((out_date-out_pdate))
    [[ $out_diffdate -lt $disable_event_for ]] || {
      i_event=$((i_event+1))
      out_pdate=$out_date
    }
    [[ $((i_event%2)) -eq 0 ]] && { echo_green  "[$i_event] ${inofy_out#*|}"; } \
                               || { echo_yellow "[$i_event] ${inofy_out#*|}"; }
  done
  exit
fi
#  }}}


#
# watch files and run command
# FIXME: Multiple event mode does not work in Vim if watched files are not a regular expression like '.'
#
# multiple events {{{


execute_command () {

  did_usercmd=false

  #
  # parse inotifywait output
  #
  out_date=${inofy_out/%|*}
  out_eventwatch=${inofy_out#*|}
  out_event=${out_eventwatch/%|*}
  out_watch=${out_eventwatch/#*|}


  #
  # disable multiple events
  #
  out_diffdate=$((out_date-out_pdate))
  [[ $out_watch = $out_pwatch && $out_diffdate -lt $disable_event_for ]] && return 1


  #
  # exclude watched files or directories
  #
  [[ $strict_exclude ]] && {
    [[ $out_watch =~ $strict_exclude ]] && return 1
  }
  [[ $strict_include ]] && {
    [[ $out_watch =~ $strict_include ]] || return 1
  }
  $skip_create_event && [[ $out_event =~ CREATE ]] && {
    if [[ -d $out_watch ]]; then
      $skip_create_dir && return 1
    else
      $skip_create_empty    && [[ ! -s $out_watch ]] && return 1
      $skip_create_nonempty && [[   -s $out_watch ]] && return 1
      $skip_create_file     && [[   -f $out_watch ]] && return 1
    fi
  }


  #
  # determine whether inotifywait should be stopped or continued
  #
  if $is_defaultevent && [[ $out_event =~ (DELETE_SELF|MOVE_SELF) ]]; then

    # FIXME: sleep a little because a watched file may be writting
    sleep 0.3
    [[ -e $out_watch ]] || return 1

    if $finished_multievent; then

      $clear_screen && clear
      did_clearcmd=true

      echo_red "$0: Cannot watch $out_watch anymore ($out_event)"

      if $is_defaultevent; then

        inofy_pid=$(search_inotifypid $$)
        [[ -z $inofy_pid ]] && {
          echo_red "$0: Cannot find inotifywait pid"
          return 1
        }

        $debug && {
          echo "Shell self pid: $$"
          ps -hx -o pid,ppid,command | egrep "$0|inotifywait" | grep -v grep
          echo "Inotifywait pid: $inofy_pid"
        }

        stopped_multievent=true
        echo_red "$0: Change intifywait options to receive a single event"
        kill -INT $inofy_pid

      fi

    fi

  fi


  #
  # save a watch information
  #
  out_pdate=$out_date
  out_pwatch=$out_watch


  #
  # convert special characters
  #
  out_dirname=$( dirname  "$out_watch")
  out_basename=$(basename "$out_watch")
  out_dirwatched=$out_dirname
  if [[ -f $out_watch ]]; then
    out_filewatched=$out_watch
    out_prefix=${out_basename%.*}
    out_extension=${out_basename##*.}
  fi

  usercmd_rep=$user_cmd
  usercmd_rep=${usercmd_rep//%b/$out_basename}
  usercmd_rep=${usercmd_rep//%d/$out_dirwatched}
  usercmd_rep=${usercmd_rep//%e/$out_extension}
  usercmd_rep=${usercmd_rep//%f/$out_filewatched}
  usercmd_rep=${usercmd_rep//%p/$out_prefix}
  usercmd_rep=${usercmd_rep//%x/exit \$?}  # QUESTION: should remove???

  out_inofy=$out_format
  out_inofy=${out_inofy//%c/$usercmd_rep}
  out_inofy=${out_inofy//%e/$out_event}
  out_inofy=${out_inofy//%w/$out_watch}
  out_inofy=${out_inofy//%i/$inofy_cmd}  # put this at last


  #
  # print inotifywait output
  #
  $clear_screen && { $did_clearcmd || clear; }
  $print_date && print_nowdate
  $eventverb && { [[ $out_inofy ]] && echo_yellow -e "$out_inofy"; }


  # XXX: an easy way to avoid error: 'bad interpreter: Text file busy'.
  #      this may happen when execution file is executed.
  sleep 0.2


  #
  # execute user command
  #
  $verbose && { echo_cyan [Result]; }
  # NOTE1: why use eval? there are some reasons. for example, user may use multiple command.
  # NOTE2: why use subshell? because no variables are changed from user command.
  time_start=$(date +%s%N)
  (eval "$usercmd_rep")
  ret=$?
  time_end=$(date +%s%N)
  time_str="$(echo "scale=2;($time_end-$time_start)/1000000000"|bc|xargs printf %.2fs)"
  $verbose && { [[ $ret -eq 0 ]] && echo_green "[Success $time_str]" || echo_red "[Failure $time_str]"; }


  did_usercmd=true


  return 0


}



out_pdate=0
out_pwatch=
did_clearcmd=false
stopped_multievent=false
$is_singleevent && finished_multievent=false \
                || finished_multievent=true

if $finished_multievent; then

  while read inofy_out; do
    execute_command || continue
  # NOTE: why use eval? because $inofy_cmd includes single quotaion
  #       ex) a="ls '<file>'" &&      $a   NG
  #           a="ls '<file>'" && eval $a   OK
  #       however, $inofy_cmd needs not contain quotaion if letters between quations do not contain space
  done < <(eval "$inofy_cmd")

  if $stopped_multievent; then

    $did_usercmd && {
      # unexpected behavior
      echo_red "$0: Failed to restart inotifywait"
      exit 1
    }

    did_clearcmd=false
    finished_multievent=false

  fi

fi

#  }}}
# single event {{{

if $stopped_multievent || $is_singleevent; then

  $verbose && echo_cyan "[Single event]"

  if $is_defaultevent; then
    inofy_cmd=${inofy_cmd//inotifywait $inofy_monitor/inotifywait}
    inofy_cmd=${inofy_cmd//$inofy_events/-e delete_self,move_self}
    $is_singleevent || print_inotifywait_and_user_commands
  fi


  while true; do

    inofy_out=$(eval "$inofy_cmd" 2>&1)
    ret=$? && [ $ret -eq 1 ] && inotify_error || { [ $ret -eq 2 ] && break; }

    # for safety
    sleep 0.2

    execute_command || continue

  done

fi
#  }}}


# TODO: load user command from a file.
# NOTE: the maximum of inotify watches is 8192.



# vim:fileencoding=utf-8
# vim:foldmethod=marker
