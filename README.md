# ISM Document to OSCAL

## Requirements
- Clone this folder to a recent Linux distribution
- Install Python3
- Install a recent version of [Saxon](https://sourceforge.net/projects/saxon/files/), the HE version is fine
- Rename whatever version you have as saxon.jar in the current directory, or adjust the SAXON variable in make_ism.sh
- Run make_ism.sh, vis:

> $ ./make_ism.sh -i document/Australian\ Government\ Information\ Security\ Manual\ \(September\ 2021\).docx -o examples
>
> Converting doc to xml...
> 
> Making ASCS XML...
> 
> Making Catalog...
> 
> Making OFFICIAL profile...
> 
> Making PROTECTED profile...
> 
> Making SECRET profile...
> 
> Making TOP_SECRET profile...
> 
> Making HTML...

Will recreate the [examples](examples) folder

# Notes
- UUIDS are consistent for each run, but updated each time
- The HTML created is a basic rendering of the OSCAL Catalog as an example

