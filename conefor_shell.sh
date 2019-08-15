# conefor R command with arguments

#set arguments

ncores=10
subbasins=FR_C_ZHYD_density_v4.csv
dist1=5
dist2=10
metric1=DdamL
metric2=DdamLS

#generate inputs for conefor
echo 'Generating conefor inputs...'
time Rscript preprocess.R $ncores $subbasins $dist1 $dist2 $metric1 $metric2 >>preprocess_out_`date '+%Y-%m-%d_%H:%M:%S'`.txt 2>&1

#run conefor
echo 'Running conefor...'
chmod 777 ./conefor2.7.3Linux
time parallel --header : --colsep ',' ./conefor2.7.3Linux -nodeFile {nodePath} -conFile {conPath} -confAdj {distances} -IIC -prefix {prefixString} :::: dIICoutlets.csv >>conefor_out_`date '+%Y-%m-%d_%H:%M:%S'`.txt 2>&1

#tidy up conefor
echo 'Tidying up outputs...'
rm *events.txt

Rscript tidyup.R $dist1 $dist2 $metric1 $metric2 >>tidyup_out_`date '+%Y-%m-%d_%H:%M:%S'`.txt 2>&1

cp *importances.txt coneforOut
#rm *IIC*
#rm *indices.txt

echo 'Finished!'