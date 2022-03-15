#! /bin/bash
set -eo pipefail
trap ctrl_c INT

readonly YELLOW=$(tput setaf 3)
readonly NC=$(tput sgr0)

readonly BACKUP_FILE=".dazzle.yaml.orig"
readonly ORIGINAL_FILE="dazzle.yaml"

function save_original {
    if [ ! -f ${BACKUP_FILE} ]; then
        echo "${YELLOW}Creating a backup of ${ORIGINAL_FILE} as it does not exist yet...${NC}" && cp ${ORIGINAL_FILE} ${BACKUP_FILE}
    fi
}

function restore_original() {
	echo "${YELLOW}Restoring backup file ${BACKUP_FILE} to original file ${ORIGINAL_FILE}${NC}"
	cp ${BACKUP_FILE} ${ORIGINAL_FILE}
}

function ctrl_c() {
	echo "${YELLOW}** Trapped CTRL-C${NC}"
	restore_original
}

function build_combination {
    combination=$1

    local exists="$(yq e '.combiner.combinations[] | select (.name=="'"$combination"'")' dazzle.yaml)"
    if [[ -z "$exists" ]]; then
        echo "combination is not defined"
        exit 1
    fi

    refs=$(get_refs "$combination")
    requiredChunks=$(get_chunks "$refs" | sort | uniq)   
    availableChunks=$(get_available_chunks)

    for ac in $availableChunks; do
        if [[ ! "${requiredChunks[*]}" =~ "${ac}" ]]; then
            dazzle project ignore "$ac"
        fi
    done
}

function get_refs {
    local ref=$1
    echo "$ref"

    refs="$(yq e '.combiner.combinations[] | select (.name=="'"$ref"'") | .ref[]' dazzle.yaml)"
    if [[ -z "$refs" ]]; then
        return
    fi

    for ref in $refs; do
        get_refs "$ref"
    done
}

function get_chunks {
    for ref in $@; do
        chunks=$(yq e '.combiner.combinations[] | select (.name=="'"$ref"'") | .chunks[]' dazzle.yaml)
        echo "$chunks"
    done
}

function get_available_chunks {
    local chunk_defs=$(ls chunks)
    for chunk in $chunk_defs;do
        local chunkYaml="chunks/${chunk}/chunk.yaml"
        if [[ -f "$chunkYaml" ]]; then
            variants=$(yq e '.variants[].name' "$chunkYaml" )
            for variant in $variants; do
                echo "$chunk:$variant"
            done
        else
          echo "$chunk"
        fi

    done
}

REPO=localhost:5000/dazzle

save_original 

if [ -n "${1}" ]; then
    build_combination "$1"
fi

# First, build chunks without hashes
dazzle build $REPO -v --chunked-without-hash
# Second, build again, but with hashes
dazzle build $REPO -v

# Third, create combinations of chunks
if [[ -n "${1}" ]]; then
    dazzle combine $REPO --combination "$1" -v
else
    dazzle combine $REPO --all -v
fi

restore_original
