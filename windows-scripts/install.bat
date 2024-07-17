rem Install a Version-Controlled IOP-Compliant R on Windows 10 Professional 64-bit


rem Settings
set run_directory="C:\iopqualr"
set run_dir=C:/iopqualr
set r_repository="http://cran.us.r-project.org"
set r_download_mirror="https://brieger.esalq.usp.br/CRAN/"
set pandoc_installer_url="http://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-windows-x86_64.msi"


if not exist %run_directory% mkdir %run_directory%


rem Download and Install R
bitsadmin /transfer R /download /priority high "https://cloud.r-project.org/bin/windows/base/old/3.4.3/R-3.4.3-win.exe" %run_directory%\R-3.4.3-win.exe
%run_directory%\R-3.4.3-win.exe /SILENT /COMPONENTS="main,x64,translations"


rem Add R Binary Directory to Path
set PATH=%PATH%;C:\Program Files\R\R-3.4.3\bin\x64\"


rem Download and Install RTools (Because some non-latest-version packages need compilation)
bitsadmin /transfer Rtools /download /priority high %r_download_mirror%/bin/windows/Rtools/Rtools35.exe %run_directory%\Rtools35.exe
%run_directory%\Rtools35.exe /SILENT


rem Set R options
@echo  options(repos=structure(c(CRAN=%r_download_mirror%))) > "C:\Program Files\R\R-3.4.3\etc\Rprofile.site"
@echo options(R_REMOTES_UPGRADE='never') >> "C:\Program Files\R\R-3.4.3\etc\Rprofile.site"
@echo options(encoding="UTF-8") >> "C:\Program Files\R\R-3.4.3\etc\Rprofile.site"
@echo Sys.setenv(LC_COLLATE="C", LANGUAGE="en",LC_TIME="C",LC_CTYPE="C") >> "C:\Program Files\R\R-3.4.3\etc\Rprofile.site"


rem Install required R packages with correct versions
Rscript -e "install.packages('devtools', type='win.binary')"
Rscript -e "remotes::install_version('mvtnorm', version='1.0-6', type='win.binary', dependencies=TRUE)"
Rscript -e "remotes::install_version('DoseFinding', version='0.9-15', type='win.binary', dependencies=TRUE, upgrade='never')"
Rscript -e "remotes::install_version('ggplot2', version='2.2.1', type='win.binary', dependencies=TRUE, upgrade='never')"
Rscript -e "install.packages('MCPMod', type='win.binary', dependencies=TRUE)"
Rscript -e "install.packages('evaluate', type='win.binary', dependencies=TRUE)"
Rscript -e "remotes::install_version('rlang', version='0.4.0', type='win.binary', upgrade='never')"
Rscript -e "devtools::install(file.path('%run_dir%', 'pkg'), upgrade='never')"

rem Install and configure tinytex
Rscript -e "tinytex::install_tinytex(extra_packages='ae')"
Rscript -e "tinytex::tlmgr_path(action='add')"

rem Update test demos.Rout file with one that has correct package and object counts
copy "%run_directory:"=%\demos.Rout" "C:\Program Files\R\R-3.4.3\tests\demos.Rout" /Y

rem Download and Install Pandoc
rem   accept license agreement and install for all users
bitsadmin /transfer Pandoc /download /dynamic /priority high %pandoc_installer_url% %run_directory%\pandoc-2.7.3-windows-x86_64.msi
%run_directory%\pandoc-2.7.3-windows-x86_64.msi

pause
@echo "all done""
