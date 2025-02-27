################################# BISU_START: Bash Internal Simple Utils #################################
# Recommended BISU PATH: /usr/local/sbin/bisu.bash
# Official Web Site: https://x-1.tech
# Define BISU VERSION
export BISU_VERSION="4.1.1"

# Set PS1
export PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# Set PS4
export PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
export AUTORUN=(
    'trap "wait" SIGCHLD'
    'trap "set_title "$DEFAULT_TITLE"" EXIT'
    'acquire_lock'
    'trap "cleanup" EXIT INT TERM HUP'
)
export HOME=$(eval echo ~${SUDO_USER:-$USER})
# BISU path
export BISU_FILE_PATH="${BASH_SOURCE[0]}"
# Default title
export DEFAULT_TITLE="-bash"
# Required files
export REQUIRED_SCRIPT_FILES=()
# Subprocesses pids to cleanup
export SUBPROCESSES_PIDS=()
# Required external commands list
export BISU_REQUIRED_EXTERNAL_COMMANDS=('uuidgen' 'md5sum' 'awk' 'yq' 'xxd' 'bc')
# Required external commands list
export REQUIRED_EXTERNAL_COMMANDS=()
# Global Variables
export ROOT_LOCK_FILE_DIR="/var/run"
export USER_LOCK_FILE_DIR="$HOME/.local/var/run"
export LOCK_FILE_DIR=""/tmp""
export LOCK_ID=""
export LOCK_FILE=""
export ROOT_LOG_FILE_DIR="/var/log"             # Root Log file location
export USER_LOG_FILE_DIR="$HOME/.local/var/log" # User Log file location
export LOG_FILE=""
export BISU_TARGET_PATH="/usr/local/sbin/bisu.bash" # Default target path for moving scripts
export REQUIRED_BASH_VERSION="5.0.0"                # Minimum required Bash version (configurable)
export PROMPT_COMMAND="set_title"
# The current file path
export CURRENT_FILE_PATH=""
# The current command by the actual script
CURRENT_COMMAND=""

# Universal function to trim whitespace
trim() {
    echo "$1" | awk '{$1=$1}1'
}

# BISU file path
bisu_file() {
    echo "$BISU_FILE_PATH"
}

# Function: command_path
# Description: According to its naming
command_path() {
    command_path=$(echo "$1" | awk '{print $1}')
    command_path=$(trim "$command_path")
    [[ -n "$command_path" ]] && echo "$command_path" || {
        echo -e "Error: Failed to get command path" >&2
        exit 1
    }
}

# Function: current_command
# Description: According to its naming
current_command() {
    if [[ -z $CURRENT_COMMAND ]]; then
        echo -e "Error: Invalid current command" >&2
        exit 1
    fi

    echo "$CURRENT_COMMAND"
}

# Function: current_file
# Description: According to its naming
current_file() {
    CURRENT_FILE_PATH=$(command_path "$(current_command)")
    if [[ -z $CURRENT_FILE_PATH ]] || ! is_file "$CURRENT_FILE_PATH"; then
        echo -e "Error: Invalid current file path: $CURRENT_FILE_PATH" >&2
        exit 1
    fi
    echo "$CURRENT_FILE_PATH"
}

# Register the current command
register_current_command() {
    current_file &>/dev/null
}

# Function: strtolower
# Description: According to its naming
strtolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Function: strtoupper
# Description: According to its naming
strtoupper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Function: substr
# Description: According to its naming
substr() {
    echo "${1:$(($2 < 0 ? ${#1} + $2 : $2)):$3}"
}

# Function: md5_sign
# Description: According to its naming
md5_sign() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

# Function: current_dir
# Description: According to its naming
current_dir() {
    echo $(dirname $(current_file)) || {
        echo -e "Error: Invalid current file path: $CURRENT_FILE_PATH" >&2
        exit 1
    }
}

# Check string start with
string_starts_with() {
    local input_string=$1
    local start_string=$2

    if [[ -z "$input_string" || -n "$start_string" && "$input_string" != "$start_string"* ]]; then
        return 1
    fi

    return 0
}

# Check string end with
string_ends_with() {
    [[ "${1: -${#2}}" == "$2" ]]
}

# Check if the current user is root (UID 0)
is_root_user() {
    if [ "$(id -u)" != 0 ]; then
        return 1
    fi
    return 0
}

# Function: is_valid_date
# Description: According to its naming
is_valid_date() {
    local date_str=$(trim "$1")

    # Check if the date matches any valid format using regular expressions
    if [[ "$date_str" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$ ||
        "$date_str" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\ ([0-9]{1,2}):([0-9]{2})$ ||
        "$date_str" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\ ([0-9]{1,2}):([0-9]{2})\ (AM|PM)$ ||
        "$date_str" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\ ([0-9]{1,2}):([0-9]{2})\ [APap][Mm]$ ]]; then
        return 0 # Valid date
    else
        return 1 # Invalid date
    fi
}

# The current log file
current_log_file() {
    local log_file_dir="$LOG_FILE_DIR"
    local log_file=""
    local filename=$(basename "$(current_file)") || {
        echo -e "Error: Invalid current file path: $CURRENT_FILE_PATH" >&2
        exit 1
    }

    # Check if log file directory is valid, otherwise set based on user privileges
    if ! [[ -n "$log_file_dir" && -e "$log_file_dir" && -d "$log_file_dir" ]]; then
        log_file_dir=$(if is_root_user; then echo "$ROOT_LOG_FILE_DIR"; else echo "$USER_LOG_FILE_DIR"; fi)
    fi

    # Default to $HOME if no valid directory found
    log_file_dir="${log_file_dir:-$HOME/.local/var/run}"

    # Remove trailing slash if exists
    [[ "$log_file_dir" =~ /$ ]] && log_file_dir="${log_file_dir%/}"

    # Construct log file directory with current date, ensuring it's only appended once
    log_file_dir="$log_file_dir/$filename"
    log_file_dir="$log_file_dir/$(date +'%Y-%m')"

    # Create directory if it doesn't exist
    if [[ ! -d "$log_file_dir" ]]; then
        mkdir -p "$log_file_dir" && chmod -R 755 "$log_file_dir" || {
            echo -e "Error: Failed to create or set permissions for $log_file_dir" >&2
            exit 1
        }
    fi

    # Final checks and log file creation
    LOG_FILE_DIR="$log_file_dir"
    log_file="$log_file_dir/$filename.log"

    touch "$log_file" || {
        echo -e "Error: Failed to create log file $log_file" >&2
        exit 1
    }

    # Validate log file creation
    if ! [[ -e "$log_file" && -f "$log_file" ]]; then
        echo -e "Error: Log file $log_file creation failed" >&2
        exit 1
    fi

    echo "$log_file"
}

# Function: log_message
# Description: Logs messages with timestamps to a specified log file, with fallback options.
# Arguments:
#   $1 - Message to log.
# Returns: None (logs message to file).
log_message() {
    local msg="$1"
    local stderr_flag="${2:-true}"
    local log_file="$(current_log_file)"
    local log_dir=$(dirname "$log_file")

    # Ensure the log directory exists
    mkdir -p "$log_dir" || {
        echo -e "Failed to create log directory: $log_dir" >&2
        exit 1
    }

    # Create the log file if it doesn't exist
    if [[ ! -f "$log_file" ]]; then
        touch "$log_file" || {
            echo -e "Failed to create log file $log_file" >&2
            exit 1
        }
    fi

    # Log the message with a timestamp to the log file and optionally to stderr
    if [[ "$stderr_flag" == "true" ]]; then
        # Log to both log file and stderr
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$log_file" >&2
    else
        # Log to the log file only
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$log_file" >/dev/null
    fi

    return 0
}

# Function to handle errors
error_exit() {
    local msg=$(trim "$1")
    log_message "Error: $msg" "true"
    exit 1
}

# Function: add_env_path
# Description: To robustly add new path to append
add_env_path() {
    local new_path=$(trim "$1")

    # Check if the argument is provided
    if [ -z "$new_path" ]; then
        log_message "No path provided to append."
        return 1
    fi

    # Check if the directory exists
    #s_dir "$new_path" || return 1

    # Convert to absolute path
    new_path=$(cd "$new_path" && pwd -P)

    # Check if the path is already in PATH to avoid duplicates
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        # Prepend colon if PATH is not empty to ensure correct parsing
        if [ -n "$PATH" ]; then
            PATH="$PATH:$new_path"
        else
            PATH="$new_path"
        fi
        export PATH
    fi
}

# Check if it's numeric
is_numeric() {
    [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && return 0 || return 1
}

# Function: is_file
# Description: According to its naming
is_file() {
    local filepath=$(trim "$1")
    [[ -z "$filepath" || ! -f "$filepath" || ! -e "$filepath" ]] && return 1 || return 0
}

# Function: is_dir
# Description: According to its naming
is_dir() {
    local dirpath=$(trim "$1")
    [[ -z "$dirpath" || ! -d "$dirpath" || ! -e "$dirpath" ]] && return 1 || return 0
}

# Function: file_exists
# Description: According to its naming
file_exists() {
    local filepath=$(trim "$1")
    if ! (is_file "$filepath" || is_dir "$filepath"); then
        log_message "File or dir $filepath does not exist."
        return 1
    fi
    return 0
}

# mkdir_p
mkdir_p() {
    local dir=$1
    local dir_frill=${2:-""}
    local start_string=${3:-""}

    # Validate input directory name
    [[ -n "$dir" ]] || {
        log_message "No directory name provided."
        return 1
    }
    string_starts_with "$dir" "$start_string" || {
        log_message "No directory name provided."
        return 1
    }

    # Prepare the directory description with a frill if provided
    local dir_description="${dir_frill:+ $dir_frill}dir: $dir"

    # Check if the directory exists, if not, create it
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            log_message "Failed to create $dir_description"
            return 1
        }
        chmod -R 755 "$dir" || {
            log_message "Failed to change permissions for $dir_description"
            return 1
        }
    fi

    return 0
}

# Function: touch_dir
# Description: According to its naming
touch_dir() {
    local target_dir=$(trim "$1")

    # Check if the directory path is valid and non-empty
    if [[ -z "$target_dir" ]]; then
        log_message "Invalid directory path provided."
        return 1
    fi

    mkdir_p "$target_dir"
    return 0
}

# Function: move_file
# Description: Moves any file to the specified target path.
# Arguments:
#   $1 - File to move (source path).
#   $2 - Target path (destination directory).
# Returns: 0 if successful, 1 if failure.
move_file() {
    local source_file=$(trim "$1")
    local target_dir=$(trim "$2")

    # Check if the source file exists
    if [[ ! -f "$source_file" ]]; then
        log_message "Source file $source_file does not exist."
        return 1
    fi

    # Touch dir
    touch_dir "$target_dir"

    # Move the file to the target path
    mv "$source_file" "$target_dir"

    # Check if the move was successful
    if [[ $? != 0 ]]; then
        log_message "Failed to move file $source_file to $target_dir"
        return 1
    fi
    return 0
}

# Function: move_current_script
# Description: Moves the current script to a specified target path using the move_file function.
# Arguments: None
# Returns: 0 if successful, 1 if failure.
move_current_script() {
    local current_script=$(current_file)
    local target_path=$(trim "$1")

    log_message "Moving current script: $current_script"
    move_file "$current_script" "$target_path"
}

# Function: move_bisu
move_bisu() {
    local current_script=$(bisu_file)
    local target_path=$(trim "$1")

    log_message "Moving BISU script to path: $target_path"
    move_file "$current_script" "$target_path"
}

# Function to check if a variable is an array
is_array() {
    local array_name=$(trim "$1")
    # Negate the test for `declare -a` using ! logic
    if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -a'; then
        return 1 # Not an array
    fi
    return 0 # Is an array
}

# Array values as string
array_values_string() {
    local array_name=$(trim "$1")
    local var_name=$(trim "$2")
    if ! is_array "$array_name" || ! is_valid_var_name "$var_name"; then
        echo ""
        return
    fi
    eval "$var_name=(\"\${$array_name[@]}\")" || error_exit "Failed to get array values."
}

# Function to add an element to a specified global array
array_unique_push() {
    local array_name=$1
    local new_value=$2
    local value_type=${3:-STRING} # Default to STRING if not provided

    # Validate the type parameter and input value
    case "$value_type" in
    INT)
        if ! [[ "$new_value" =~ ^-?[0-9]+$ ]]; then
            log_message "Value must be an integer."
            return 1
        fi
        ;;
    FLOAT)
        if ! [[ "$new_value" =~ ^-?[0-9]*\.[0-9]+$ ]]; then
            log_message "Value must be a float."
            return 1
        fi
        ;;
    STRING)
        # No specific validation for STRING
        ;;
    *)
        log_message "Invalid type specified. Use STRING, INT, or FLOAT."
        return 1
        ;;
    esac

    # Ensure the global array exists
    if ! is_array "$array_name"; then
        log_message "Array $array_name does not exist."
        return 1
    fi

    # Access the global array using indirect reference
    eval "array=(\"\${$array_name[@]}\")"

    # Function to check if item exists in an array
    item_exists() {
        local item=$1
        shift
        local element
        for element in "$@"; do
            if [[ "$element" == "$item" ]]; then
                return 0
            fi
        done
        return 1
    }

    # Check if the value is already in the array
    if item_exists "$new_value" "${array[@]}"; then
        log_message "Item already exists in array."
        return 1
    fi

    # Append the new value to the array
    # Using indirect reference to modify the global array
    eval "$array_name+=(\"$new_value\")"

    return 0
}

# Function: array_merge
# Description: Function to merge 2 global arrays
array_merge() {
    local array1="$1" array2="$2" result="$3"
    if [[ $# -ne 3 ]] || ! is_array "$array1" || ! is_array "$array2" || ! is_array "$array3"; then
        log_message "Requires exactly three arguments (two array names and one result name)."
        return 1
    fi

    # Initialize result array as empty
    eval "$result=()"

    # Add unique elements from array1 and array2
    for array in "$array1" "$array2"; do
        eval "for item in \${$array[@]}; do
        [[ ! \${result[@]} =~ \"\$item\" ]] && result+=(\"\$item\")
    done"
    done
}

# Function: array_unique
# Description: To remove duplicates from a global array
array_unique() {
    local array_name="$1"
    if [[ $# -ne 1 ]] || ! is_array "$array_name"; then
        log_message "Requires exactly one argument (array name)."
        return 1
    fi
    eval "$array_name=($(echo \${$array_name[@]} | tr ' ' '\n' | sort -u | tr '\n' ' '))"
}

# Function: is_valid_version
# Description: Validates a version number in formats vX.Y.Z, X.Y.Z, X.Y, or X/Y/Z.
# Arguments:
# $1 - Version number to validate.
# Returns: 0 if valid, 1 if invalid.
is_valid_version() {
    local version="$1"
    # Check for version formats
    if [[ "$version" =~ ^[v]?[0-9]+(\.[0-9]+)*(/[0-9]+)*$ ]]; then
        return 0
    else
        log_message "Invalid version format: $version"
        return 1
    fi
}

# Function: check_bash_version
# Description: Verifies that the installed Bash version is greater than or equal to the specified required version.
# Returns: 0 if Bash version is valid, 1 if not.
check_bash_version() {
    if ! is_valid_version "$REQUIRED_BASH_VERSION"; then
        log_message "Illegal version number of required Bash"
        return 1
    fi

    local bash_version=$(bash --version | head -n 1 | awk '{print $4}')

    # Extract the major, minor, and patch version components
    local major=$(echo "$bash_version" | cut -d '.' -f 1)
    local minor=$(echo "$bash_version" | cut -d '.' -f 2)
    local patch=$(echo "$bash_version" | cut -d '.' -f 3)

    # Log the current Bash version
    log_message "Detected Bash version: $bash_version"

    # Compare the version with the required version
    IFS='.' read -r req_major req_minor req_patch <<<"$REQUIRED_BASH_VERSION"

    if [[ "$major" -gt "$req_major" ]] ||
        { [[ "$major" == "$req_major" && "$minor" -gt "$req_minor" ]] ||
            { [[ "$major" == "$req_major" && "$minor" == "$req_minor" && "$patch" -ge "$req_patch" ]]; }; }; then
        log_message "Bash version is sufficient: $bash_version"
        return 0
    else
        log_message "Bash version is too old. Requires version $REQUIRED_BASH_VERSION or greater. Detected version: $bash_version"
        return 1
    fi
}

# Function to validate a variable name
is_valid_var_name() {
    local var_name=$(trim "$1")
    if [[ -z "$var_name" || ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 1
    fi
    return 0
}

# Universal function to validate IP address
is_valid_ip() {
    local ip=$(trim "$1")
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        local IFS=.
        read -r i1 i2 i3 i4 <<<"$ip"
        if [[ $i1 -le 255 && $i2 -le 255 && $i3 -le 255 && $i4 -le 255 ]]; then
            return 0
        fi
    fi
    return 1
}

# Universal function to validate port number
is_valid_port() {
    local port=$(trim "$1")
    if [[ $port =~ ^[0-9]+$ ]] && ((port >= 0 && port <= 65535)); then
        return 0
    fi
    return 1
}

# Function to convert YAML to JSON
yaml_to_json() {
    local yaml="$(trim "$1")"
    if ! command -v yq &>/dev/null; then
        echo "{}"
        return
    fi
    yq -o json 2>/dev/null <<<"$yaml" || echo "{}"
}

# Private global variables to simulate associative array behavior
declare -a _ASSOC_KEYS=()
declare -a _ASSOC_VALUES=()

# Convert plaintext YAML-like key:value pairs into global variables simulating an associative array
yaml_to_array() {
    local input
    if [ $# -eq 0 ]; then
        input=$(cat)
    else
        input="$(trim "$1")"
    fi

    _ASSOC_KEYS=()   # Clear existing keys
    _ASSOC_VALUES=() # Clear existing values

    while IFS=':' read -r key value; do
        if [ -z "$key" ]; then
            continue # Skip empty lines or keys
        fi

        key=$(echo "$key" | tr -d '"' | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print}')
        value=$(echo "$value" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print}')

        # Handle value types
        case "$value" in
        "true" | "false") ;;
        [0-9]* | [0-9]*.[0-9]*) ;;
        *) value="$(echo "$value" | awk '{gsub(/"/, ""); print}')" ;; # Escape double quotes within strings
        esac

        _ASSOC_KEYS+=("$key")
        _ASSOC_VALUES+=("$value")
    done <<<"$input"
}

# Function to access elements like an associative array using global variables
arr_get_val() {
    if ! is_array "_ASSOC_KEYS" || ! is_array "_ASSOC_VALUES"; then
        echo ""
        return
    fi

    local search_key=$(trim "$1")
    for ((i = 0; i < ${#_ASSOC_KEYS[@]}; i++)); do
        if [ "${_ASSOC_KEYS[$i]}" = "$search_key" ]; then
            echo $(trim "${_ASSOC_VALUES[$i]}")
            return
        fi
    done
    echo ""
}

# To validate if a word is in a string
word_exists() {
    local word=$(trim "$1")
    local string=$(trim "$2")
    local match_whole_word=${3:-true}
    [[ "${match_whole_word}" == "true" ]] && [[ " ${string:-} " =~ " $word " ]] || [[ "${string:-}" =~ "$word" ]]
}

# Generate a secure random UUIDv4 (128 bits)
uuidv4() {
    local uuidv4=""
    # Use /dev/urandom to generate random data and format as hex
    uuidv4=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' | awk '{print tolower($0)}')
    if [[ -z $(trim "$uuidv4") ]]; then
        uuidv4=$(uuidgen | tr -d '-' | awk '{print tolower($0)}')
    fi
    echo "$uuidv4"
}

# Function to convert hex to string
hex2str() {
    local hex_string=$(trim "$1")
    echo -n "$hex_string" | tr -d '[:space:]' | xxd -r -p || echo ""
}

# Function to convert string to hex
str2hex() {
    local input_string=$(trim "$1")
    local having_space=${2:-true} # Having space as separator for standard hex
    local result=""

    result=$(echo -n "$input_string" | xxd -p | tr -d '[:space:]' || echo "")
    if $having_space && [[ -n "$result" ]]; then
        result=$(echo -n "$result" | awk '{ gsub(/(..)/, "& "); print }')
    fi
    echo "$result"
}

# Generate random string based on uuidv4
random_string() {
    local length="${1:-32}"
    local type="${2:-MIXED}"
    local max_length=1024

    # Validate length
    if ! [[ "$length" =~ ^[0-9]+$ ]] || ((length < 1)); then
        echo ""
        return
    fi

    # Ensure length does not exceed max_length
    if ((length > max_length)); then
        length=$max_length
    fi

    # Define character sets
    local charset_letters="abcdefghijklmnopqrstuvwxyz"
    local charset_numbers="0123456789"

    # Determine the character set based on type
    local charset
    case "$type" in
    LETTERS)
        charset="$charset_letters"
        ;;
    NUMBERS)
        charset="$charset_numbers"
        ;;
    MIXED)
        charset="$charset_letters$charset_numbers"
        ;;
    *)
        echo ""
        return
        ;;
    esac

    # Ensure the charset is large enough
    if ((${#charset} < length)); then
        echo ""
        return
    fi

    # Shuffle the charset to randomize character order
    local shuffled_charset
    shuffled_charset=$(echo "$charset" | fold -w1 | shuf | tr -d '\n')

    # Generate the random string without repeated characters
    echo "$shuffled_charset" | head -c "$length" || echo ""
}

# Function to check if a command is existent
command_exists() {
    local commandString=$(trim "$1")
    if [[ -z "$commandString" ]]; then
        return 0
    fi
    if ! command -v "$commandString" &>/dev/null; then
        return 1
    fi
    return 0
}

# Function to check existence of external commands
check_commands_list() {
    local array_name=$(trim "$1")
    local invalid_commands_count=0
    local invalid_commands=""

    if ! is_array "$array_name"; then
        error_exit "Invalid array name provided when checking commands."
        return 1
    fi

    array_values_string "$array_name" "commands"
    # Check if the array is empty
    if [[ ${#commands[@]} == 0 ]]; then
        return 0
    fi

    for commandString in "${commands[@]}"; do
        # Check if the command exists
        if ! command_exists "$commandString"; then
            ((invalid_commands_count++))
            invalid_commands+=", '$commandString'"
            continue
        fi
    done

    # Report the invalid commandString if any
    if [[ $invalid_commands_count -gt 0 ]]; then
        invalid_commands=${invalid_commands:1}
        error_exit "Missing $invalid_commands_count command(s):$invalid_commands"
    fi

    return 0
}

# The current file's run lock by signed md5 of full path
current_lock_file() {
    if [[ -z "$LOCK_ID" ]]; then
        local lock_file_dir="$LOCK_FILE_DIR"
        if ! is_dir "$lock_file_dir"; then
            if is_root_user; then
                lock_file_dir="$ROOT_LOCK_FILE_DIR"
            else
                lock_file_dir="$USER_LOCK_FILE_DIR"
            fi
        fi

        if ! is_dir "$lock_file_dir"; then
            lock_file_dir="$HOME/.local/var/run"
            touch_dir "$lock_file_dir"
        fi

        if ! is_dir "$lock_file_dir"; then
            error_exit "Lock file creation failed."
        fi

        if string_ends_with "$lock_file_dir" "/"; then
            lock_file_dir=$(substr "$lock_file_dir" -1)
        fi

        LOCK_FILE_DIR="$lock_file_dir"
        LOCK_ID=$(md5_sign "$(current_command)")
        LOCK_FILE="$LOCK_FILE_DIR/$(basename $(current_file))_$LOCK_ID.lock" || {
            error_exit "Failed to set LOCK_FILE."
        }
    fi

    if [[ -z "$LOCK_ID" ]]; then
        error_exit "Could not set LOCK_ID."
    fi

    echo "$LOCK_FILE"
}

# Get the real path
get_real_path() {
    local file=$(trim "$1")
    local find_in_path=$(trim "$2")
    find_in_path="${find_in_path:-$(pwd)}"

    if [[ -z "$file" ]]; then
        echo ""
        return
    fi

    $file=$(eval echo "$file")

    if string_starts_with "$file" "/" && is_file "$file"; then
        echo "$file"
        return
    fi

    local find_in_path="$find_in_path"

    if string_ends_with "$find_in_path" "/"; then
        find_in_path=$(trim_suffix "$find_in_path" "/")
    fi

    if [[ "$find_in_path" == "." ]]; then
        find_in_path="$(dirname "$CURRENT_FILE_PATH")"
    fi

    if ! is_file "$find_in_path/$file"; then
        echo ""
        return
    fi

    echo "$find_in_path/$file"
}

# Function to acquire a lock to prevent multiple instances
acquire_lock() {
    local lock_file=$(current_lock_file)
    [[ -n "$lock_file" ]] || error_exit "Failed to acquire lock."
    exec 200>"$lock_file"
    flock -n 200 || error_exit "An instance is running: $lock_file"
}

# Function to release the lock
release_lock() {
    local lock_file=$(current_lock_file)
    ! is_file "$lock_file" && return 1
    flock -u 200 && revert_title && rm -f "$lock_file"
}

# Trap function to handle script termination
cleanup() {
    if ! is_array "SUBPROCESSES_PIDS"; then
        error_exit "Invalid SUBPROCESSES_PIDS array."
    fi

    for pid in "${SUBPROCESSES_PIDS[@]}"; do
        kill -SIGTERM "$pid" 2>/dev/null
    done

    release_lock
    exit 0
}

# Function to dynamically call internal functions
call_func() {
    local func_name="$1"
    shift # Remove the function name from the parameter list
    if declare -f "$func_name" >/dev/null; then
        "$func_name" "$@" # Call the function with the remaining parameters
    else
        log_message "Function '$func_name' not found."
    fi
}

# Function to set the terminal title
set_title() {
    local title=$(trim "$1")
    if [[ -n "$title" ]]; then
        echo -ne "\033]0;${title}\007"
    fi
    return 0
}

# Function to revert the terminal title
revert_title() {
    set_title "$DEFAULT_TITLE"
    return 0
}

# Add new element to pending to load script list, param 1 as the to load script file
import_script() {
    local script=$(trim "$1")
    if ! is_file "$script"; then
        error_exit "Failed to import script: $script"
    fi
    source "$script" || { error_exit "Failed to import script: $script"; }
}

# Automatically import required scripts
load_required_scripts() {
    array_unique "REQUIRED_SCRIPT_FILES"
    if ! is_array "REQUIRED_SCRIPT_FILES"; then
        error_exit "Invalid REQUIRED_SCRIPT_FILES array."
    fi

    for script in "${REQUIRED_SCRIPT_FILES[@]}"; do
        import_script "$script"
    done

    return 0
}

# Function to execute a command robustly
execute_command() {
    local commandString=$(trim "$1")
    eval "$commandString" || error_exit "Failed to execute command: $commandString"
}

# Push an element in the array
add_subprocess_pid() {
    local new_pid=$(trim "$1")
    array_unique_push $SUBPROCESSES_PIDS "$new_pid" "INT" || return 1
    return 0
}

# Count processes number
check_processes() {
    local process_name=$(trim "$1")
    if [[ $(pgrep -f "$process_name" | wc -l) -ge $WORKERS_NUMBER ]]; then
        log_message "Maximum clamscan processes reached. Waiting for availability."
        while [[ $(pgrep -f "$process_name" | wc -l) -ge $WORKERS_NUMBER ]]; do
            sleep 2
            # Apply CPU throttling after the process starts
            (
                "$CPUTHROTTLE" set $process_name $PROCESS_EXPECTED_USAGE
            ) &
            local throttle_pid=$!
            add_subprocess_pid $throttle_pid

            wait $throttle_pid
            sleep 2
        done
    fi
}

# Start autorun list
autorun_start() {
    if ! is_array "AUTORUN"; then
        error_exit "Invalid AUTORUN array."
    fi

    for command in "${AUTORUN[@]}"; do
        execute_command "$command"
    done

    return 0
}

# Function to initialise BISU
initialise() {
    register_current_command # Required to be the 1st start
    autorun_start
    check_commands_list "BISU_REQUIRED_EXTERNAL_COMMANDS"
    check_commands_list "REQUIRED_EXTERNAL_COMMANDS"
    load_required_scripts
}

# Confirm to install BISU
confirm_to_install_bisu() {
    local arg
    # Trim and convert input to lowercase
    arg=$(strtolower "$(trim "$1")")

    # Only proceed if the input matches "bisu_install"
    if [[ "$arg" == "bisu_install" ]]; then
        read -p "Are you sure to install BISU? (Y/n): " c
        c="${c:-y}" # Default to 'y' if input is empty
        if [[ "$c" =~ ^[Yy]$ ]]; then
            move_bisu
        fi
    fi
}

# bisu autorun function
bisu_main() {
    # initialisation actions
    initialise

    local action=$(trim "$1")
    local param=$(trim "$2")

    case "$action" in
    "bisu_install") confirm_to_install_bisu "$action" ;;
    *) ;;
    esac
}
################################################ BISU_END ################################################
