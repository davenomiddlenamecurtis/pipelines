# if the BAM files are not where the pipeline is expecting to find them, make symbolic links to *.bam and *.bai files

realFolder=/goon2/project99/bipolargenomes_raw/ingest/forlab/addRG
homeFolder=/cluster/project8/bipolargenomes
oFolder=$homeFolder/aligned

echo Using $realFolder as location for bam files

if [ ! -e $oFolder ]; then mkdir $oFolder; fi

find $oFolder -name '*.ba?' -print | while read fullName 
do 
	echo $fullName
	fileName=${fullName##*/}
	root=${filename%.*}
	ID=${root%_*}
	symLink=$oFolder/aligned/$ID/$fileName
	if [ ! -e $oFolder/aligned/$ID ]; then mkdir $oFolder/aligned/$ID ;  fi
	if [ -e $symLink ]; then rm $symLink; fi
	echo making this link: ln -s $fullName $symLink
	ln -s $fullName $symLink
done
