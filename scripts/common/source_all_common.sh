#Single file that pulls in all the other common files

readonly COMMON_DIR="$(dirname "${BASH_SOURCE[0]}")"

source "$COMMON_DIR/ui.sh"
source "$COMMON_DIR/functions.sh"
source "$COMMON_DIR/vars.sh"
