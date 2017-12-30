#!/usr/bin/env bash
# The MIT License (MIT)
# Copyright Happystack


# colors
readonly DEFAULTCOLOR='\e[39m'
readonly LIGHTGREY='\e[38;5;240m'


# size
readonly WIDTH="$(tput cols)"
readonly HEIGHT="$(tput lines)"


# symbols
readonly TOPLEFTCORNER='╭'
readonly BOTTOMLEFTCORNER='╰'
readonly TOPRIGHTCORNER='╮'
readonly BOTTOMRIGHTCORNER='╯'
readonly TOPSEPARATOR='┬'
readonly BOTTOMSEPARATOR='┴'
readonly LEFTSEPARATOR='├'
readonly RIGHTSEPARATOR='┤'
readonly CROSSINGSEPARATOR='┼'
readonly XLINE='─'
readonly YLINE='│'



##
# concateRow
#
# @desc: concat the row string with left, fill and right.
#
# @usage: concateRow <left> <fill> <right>
##
concateRow() {
  # failsafe for having all required parameters
  if [[ "${#@}" -lt 3 ]]; then
    echo 'usage: concateRow <left> <fill> <right>'  >&2
    exit 1
  fi

  # variables
  local row
  local left="${1}"
  local fill="${2}"
  local right="${3}"

  # build the row
  row+="${LIGHTGREY}${left}"
  row+="${fill}"
  row+="${right}${DEFAULTCOLOR}"

  # export row
  echo "${row}"
}


##
# cellSpacing
#
# @desc: return a string with the cell empty spaces
#
# @usage: cellSpacing <number of spaces>
##
cellSpacing() {
  # variables
  local fill=()

  # fill the cell with empty space
  for (( i = 0; i < $1; i++ )); do
    fill+=("-")
  done

  # export
  echo "$(printf "%s" "${fill[@]}")"
}


##
# cell
#
# @desc: return a string with the cell
#
# @usage: cell <content> <space length>
##
cell() {
  # variables
  local fill=()
  local content="${1}"
  local length="${2}"

  fill+="${DEFAULTCOLOR}${content}${LIGHTGREY}"
  fill+=$(cellSpacing "${length}")

  # export
  echo "$(printf "%s" "${fill[@]}")"
}


##
# content
#
# @desc: return a string with the row content with formatted cells
#
# @usage: content <columnsArray> <contentArray>
##
content() {
  local columns=$1
  local content=$2

  IFS=', ' read -r -a columns <<< "${columns}"
  IFS=', ' read -r -a content <<< "${content}"
  unset IFS

  # loop over the n-1 cells
  for (( i = 0; i < "${#columns[@]}"; i++ )); do
    local cellLength
    local contentEscaped
    contentEscaped=$(echo -e ${content[i]} | sed "s/[\\]e\[[0-9;]*m//g")
    local contentLength="${#contentEscaped}"
    # set the length of the cell
    if [[ $i = 0 ]]; then
      # first cell length is same than the first column x position
      cellLength=$(( columns[i] - contentLength ))
    else
      # the other cells length are the difference between current column and previous column
      cellLength=$(( columns[i] - columns[i-1] - contentLength - 1 ))
    fi
    # fill the cell
    fill+=$(cell "${content[i]}" "${cellLength}")
    fill+="${YLINE}"
  done

  # fill the last cell
  local lastCellLength
  local lastContentEscaped
  lastContentEscaped=$(echo -e ${content[${#columns[@]}]]} | sed "s/[\\]e\[[0-9;]*m//g")
  local lastContentLength="${#contentEscaped}"

  # get the last cell length
  lastCellLength=$(( ( WIDTH - 3 ) - columns[${#columns[@]}-1] - lastContentLength ))

  # fill the last cell
  fill+=$(cell "${content[${#columns[@]}]}" "${lastCellLength}")

  # export fill
  echo "${fill}"
}


##
# border
#
# @desc: return a string with the border row
#
# @usage: content <columnsArray> <separator>
##
border() {
  local columns=$1
  local separator=$2

  IFS=', ' read -r -a columns <<< "${columns}"
  unset IFS
  # columns
  # separator
  # export: fill
  for (( i=0, j=0; i < $(( WIDTH - 2 )); i++ )); do
    if [[ ${#columns} != 0 && $i = "${columns[$j]}" ]]; then
      fill+="${separator}"
      ((j+=1))
    else
      fill+="${XLINE}"
    fi
  done

  echo "${fill}"
}



##
# row
#
# @desc: concate and return a row
#
# @usage: row [top|middle|bottom|separator] [options]
#
# @options:
#   --column={columnArray}
#   --content={contentArray}
#   --up
#   --down
#   --cross
#
# @examples:
#   row top
#   row top --columns="${colsArray}"
#   row middle
#   row separator
#   row separator --columns="${colsArray}" --up
##
row() {
  # variables
  local row
  local left
  local right
  local fill
  local columns
  local rowType
  local separator="${XLINE}"
  local content

  # get positional parameters and configure the script according to what was passed
  for i in "$@"; do
    local option="${i}"
    case "${option}" in
      top)
        left="${TOPLEFTCORNER}"
        right="${TOPRIGHTCORNER}"
        rowType='top'
        separator="${TOPSEPARATOR}"
        shift
        ;;
      bottom)
        left="${BOTTOMLEFTCORNER}"
        right="${BOTTOMRIGHTCORNER}"
        rowType='bottom'
        separator="${BOTTOMSEPARATOR}"
        shift
        ;;
      middle)
        left="${YLINE}"
        right="${YLINE}"
        rowType='middle'
        separator="${YLINE}"
        shift
        ;;
      separator)
        left="${LEFTSEPARATOR}"
        right="${RIGHTSEPARATOR}"
        rowType='separator'
        shift
        ;;
      --up)
        separator="${BOTTOMSEPARATOR}"
        shift
        ;;
      --down)
        separator="${TOPSEPARATOR}"
        shift
        ;;
      --cross)
        separator="${CROSSINGSEPARATOR}"
        shift
        ;;
      --columns=*)
        # pull array from args
        IFS=', ' read -r -a columns <<< "${option#*=}"
        unset IFS
        # and sort it
        columns=("$( printf "%s\n" "${columns[@]}" | sort -n )")
        # shellcheck disable=SC2128
        # shellcheck disable=SC2206
        columns=($columns)
        shift
        ;;
      --content=*)
        # pull array from args
        IFS=', ' read -r -a content <<< "${option#*=}"
        unset IFS
        shift
        ;;
      *)
        # Unknown option
        echo "Error: Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done

  # deal with a border row or a content row
  if [[ $rowType != 'middle' ]]; then
    # fill the row with its border content
    fill+="$( border "${columns[*]}" "${separator}" )"
  else
    # fill the row with content
    fill+="$( content "${columns[*]}" "${content[*]}" )"
  fi

  # build the table row
  row="$( concateRow "${left}" "${fill}" "${right}" )"

  # export row
  echo "${row}"
}


# failsafe for having all required parameters
if [[ "${#@}" -lt 1 ]]; then
  echo 'pass the correct paramaters'  >&2
  exit 1
fi

# Call `row` after everything has been defined.
row "$@"
