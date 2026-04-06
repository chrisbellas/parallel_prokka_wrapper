#!/bin/bash

# Run prokka on multiple assemblies using GNU parallel
# Usage: ./run_prokka.sh --assembly_folder <folder> [--proteins <fasta>] [--jobs <n>] [--cpus <n>]

set -euo pipefail

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 --assembly_folder <folder> [--proteins <fasta>] [--jobs <n>] [--cpus <n>]"
    echo ""
    echo "Options:"
    echo "  --assembly_folder  Folder containing assembly .fasta/.fna files (required)"
    echo "  --proteins         Proteins fasta file for annotation, or 'none' to skip (optional)"
    echo "  --jobs, -j         Number of parallel jobs (default: 4)"
    echo "  --cpus             CPUs per prokka run (default: 2)"
    echo ""
    echo "Dependencies:"
    echo "  prokka             Prokaryotic genome annotation tool"
    echo "  parallel           GNU parallel for concurrent job execution"
    exit 1
fi

# Default values
ASSEMBLY_FOLDER=""
PROTEINS=""
JOBS=4
CPUS=2

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --assembly_folder)
            ASSEMBLY_FOLDER="$2"
            shift 2
            ;;
        --proteins)
            PROTEINS="$2"
            shift 2
            ;;
        --jobs|-j)
            JOBS="$2"
            shift 2
            ;;
        --cpus)
            CPUS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --assembly_folder <folder> [--proteins <fasta>] [--jobs <n>] [--cpus <n>]"
            echo ""
            echo "Options:"
            echo "  --assembly_folder  Folder containing assembly .fasta/.fna files (required)"
            echo "  --proteins         Proteins fasta file for annotation, or 'none' to skip (optional)"
            echo "  --jobs, -j         Number of parallel jobs (default: 4)"
            echo "  --cpus             CPUs per prokka run (default: 2)"
            echo ""
            echo "Dependencies:"
            echo "  prokka             Prokaryotic genome annotation tool"
            echo "  parallel           GNU parallel for concurrent job execution"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check required arguments
if [[ -z "$ASSEMBLY_FOLDER" ]]; then
    echo "Error: --assembly_folder is required"
    exit 1
fi

if [[ ! -d "$ASSEMBLY_FOLDER" ]]; then
    echo "Error: Assembly folder '$ASSEMBLY_FOLDER' does not exist"
    exit 1
fi

# Normalise 'none' to empty string, then validate if a file was specified
[[ "$PROTEINS" == "none" ]] && PROTEINS=""
if [[ -n "$PROTEINS" && ! -f "$PROTEINS" ]]; then
    echo "Error: Proteins file '$PROTEINS' does not exist"
    exit 1
fi

# Check dependencies
if ! command -v prokka &> /dev/null; then
    echo "Error: prokka is not installed or not in PATH"
    echo "  Install: conda install -c conda-forge -c bioconda prokka"
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    echo "Error: GNU parallel is not installed"
    echo "  Install: conda install -c conda-forge parallel"
    exit 1
fi

# Find assemblies (both .fasta and .fna)
ASSEMBLIES=$(find "$ASSEMBLY_FOLDER" -maxdepth 1 -type f \( -name "*.fasta" -o -name "*.fna" \) | sort)
ASSEMBLY_COUNT=$(echo "$ASSEMBLIES" | grep -c . || true)

if [[ "$ASSEMBLY_COUNT" -eq 0 ]]; then
    echo "Error: No .fasta or .fna files found in '$ASSEMBLY_FOLDER'"
    exit 1
fi

# Create output directory
OUTPUT_DIR="$ASSEMBLY_FOLDER/prokka_out"
mkdir -p "$OUTPUT_DIR"

echo "Found $ASSEMBLY_COUNT assemblies in $ASSEMBLY_FOLDER"
echo "Using $JOBS parallel jobs with $CPUS CPUs each"
echo "Proteins file: ${PROTEINS:-none (prokka default)}"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Export static variables so run_prokka can access them from the environment
export PROKKA_PROTEINS="$PROTEINS"
export PROKKA_OUTPUT_DIR="$OUTPUT_DIR"
export PROKKA_TOTAL="$ASSEMBLY_COUNT"
export PROKKA_CPUS="$CPUS"

# Define the prokka function for parallel
run_prokka() {
    fasta="$1"
    current="$2"
    # Remove both .fasta and .fna extensions
    basename=$(basename "$fasta" .fasta)
    basename=$(basename "$basename" .fna)

    echo "[$current/$PROKKA_TOTAL] Processing: $basename"
    proteins_arg=()
    [[ -n "$PROKKA_PROTEINS" ]] && proteins_arg=(--proteins "$PROKKA_PROTEINS")
    prokka "${proteins_arg[@]}" \
           --cpus "$PROKKA_CPUS" \
           --compliant \
           --force \
           --outdir "${PROKKA_OUTPUT_DIR}/${basename}" \
           --prefix "${basename}" \
           --quiet \
           "$fasta"
    echo "[$current/$PROKKA_TOTAL] Completed: $basename"
}

export -f run_prokka

# Run prokka in parallel with progress tracking
echo "$ASSEMBLIES" | parallel -j "$JOBS" run_prokka {} {#}

echo ""
echo "All $ASSEMBLY_COUNT assemblies processed!"
echo "Results saved to: $OUTPUT_DIR"
