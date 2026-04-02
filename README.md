# run_prokka.sh

A wrapper script to run [Prokka](https://github.com/tseemann/prokka) on multiple assemblies in parallel using [GNU parallel](https://www.gnu.org/software/parallel/).

## Usage


./run_prokka.sh --assembly_folder <folder> [--proteins <fasta>] [--jobs <n>] [--cpus <n>]


## Options

--assembly_folder` — Folder containing `.fasta` / `.fna` assembly files (required)
--proteins` — Proteins FASTA file for annotation, or `none` to skip (optional)
--jobs`, `-j` — Number of parallel jobs (default: 4)
--cpus` — CPUs per Prokka run (default: 2)

## Examples

Run with a custom proteins file:

./run_prokka.sh --assembly_folder assemblies/ --proteins my_proteins.fasta


Run without a proteins file (Prokka default annotation):

./run_prokka.sh --assembly_folder assemblies/
./run_prokka.sh --assembly_folder assemblies/ --proteins none


Run with more parallelism:

./run_prokka.sh --assembly_folder assemblies/ --jobs 8 --cpus 4


## Output

Results are written to `<assembly_folder>/prokka_out/<sample_name>/`.

## Dependencies

Install via conda:

conda install -c conda-forge -c bioconda prokka
conda install -c conda-forge parallel
[Prokka](https://github.com/tseemann/prokka) — Seemann T. *Prokka: rapid prokaryotic genome annotation.* Bioinformatics 2014. doi:[10.1093/bioinformatics/btu153](https://doi.org/10.1093/bioinformatics/btu153)
[GNU parallel](https://www.gnu.org/software/parallel/) — Tange O. *GNU Parallel - The Command-Line Power Tool.* USENIX Magazine 2011. doi:[10.5281/zenodo.16303](https://doi.org/10.5281/zenodo.16303)
