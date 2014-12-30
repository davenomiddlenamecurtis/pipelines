# add indices to a set of bam files if the bam.bai does not already exist and is non-zero size
# this script expects bam files to be in subfolder of oFolder
# if this is not set then the default value below will be used

############ general folders, no need to update these
software=/cluster/project8/vyp/vincent/Software
samtools=${software}/samtools-1.1/samtools

bamFolder=/goon2/project99/bipolargenomes_raw/ingest
homeFolder=/cluster/project8/bipolargenomes
cd $homeFolder
taskFolder=$homeFolder/iB

nhours=10
ncores=1
vmem=6 
memory=2
queue=queue6
scratch=0

if [ .$oFolder == . ]
then
oFolder=$bamFolder/forlab/addRG
fi

echo Using $oFolder as location for bam files to be indexed
supportFrame=$oFolder/addRGsupport.tab

## DC bit because we already have bam files:
if [ -e $supportFrame ] ; then rm $supportFrame ; fi
echo root fullName > $supportFrame
find $oFolder -name '*.bam' -print | while read fullName ;
	do
	echo $fullName; 
	ID=${fullName##*/};
	ID=${ID%.*};
	echo $ID $fullName >> $supportFrame
	done
	
if [ ! -e $taskFolder ] ; then mkdir $taskFolder ; fi
if [ ! -e $taskFolder/submission ] ; then mkdir $taskFolder/submission ; fi
if [ ! -e $taskFolder/out ] ; then mkdir $taskFolder/out ; fi
if [ ! -e $taskFolder/error ] ; then mkdir $taskFolder/error ; fi

mainScript=$taskFolder/submission/indexBams.sh
mainTable=$taskFolder/submission/indexBams_table.sh
if [ -e $mainTable ] ; then rm  $mainTable ; fi
echo firstLineToBeIgnored > $mainTable
# this is because array is indexed from 0 but tasks are indexed from 1
    tail -n+2 $supportFrame | while read root fullName
    do
           script=`echo $mainScript | sed -e 's/.sh$//'`_${code}.sh
           echo $script >> $mainTable
           echo " 
		   if [ -s $fullName.bai ] 
		   then 
		   echo $fullName.bai already exists, exiting...
		   exit 
		   else
		   $samtools index $fullName
		   fi 
           " > $script
    done

njobs=`cat $mainTable | wc -l`
njobs=$njobs-1 # ignore first line
	
echo "
#!/bin/bash
#$ -S /bin/bash
#$ -o $taskFolder/out
#$ -e $taskFolder/error
#$ -cwd
#$ -pe smp ${ncores}
#$ -l scr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -tc 25
#$ -t 1-${njobs}
#$ -V
#$ -R y
array=( \`cat \"${mainTable}\" \`)
script=\${array[ \$SGE_TASK_ID ]}
root=\${script##*/};
root=\${root%.*};
date
echo \$script
sh \$script  1> $taskFolder/out/\$root.out 2> $taskFolder/error/\$root.err
date
" > $mainScript


    echo "Main submission scripts and tables"
    wc -l $mainScript $mainTable
