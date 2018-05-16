function RISKDataImporter(dir)

%“version 1 risk and loss” (out of scanner kable EPRIME tasks)

!ls -d /import/monstrum/????/subjects/*/*_*/data/econ/risk/*.txt > Riskfilenames.txt
%gets 183 subjects from day2 and fndm

!ls -d /import/monstrum/????/subjects/*/*_*/data/econ/loss/*.txt >> Riskfilenames.txt
%gets 182 subjects from day2 and fndm

%fndm2 did not obtain risk or loss separately as far as I know (was obtained for most subjects as part of day2 or fndm)

!ls -d /import/monstrum/nodra/subjects/*_*/behav*/*neuroec/Risk*.txt >> Riskfilenames.txt
%for nodra gets risk for 99 of 105 subjects with a behavioral folder and 106 total subjects listed in the subjects directory

!ls -d /import/monstrum/nodra/subjects/*_*/behav*/*neuroec/*Loss*.txt >> Riskfilenames.txt
%for nodra gets loss for 98 subjects with a behavioral folder and 106 total subjects listed in the subjects directory

!ls -d /import/monstrum/grmpy/subjects/*_*/behavioral/neuroec/Risk*.txt >> Riskfilenames.txt
%for grmpy gets risk for 62 of 63 subj with behavioral folder and 64 total subjects listed in the subjects directory

!ls -d /import/monstrum/grmpy/subjects/*98831_*/behavioral/neuroec/Loss*.txt >> Riskfilenames.txt
%for grmpy gets loss for 62 of 63 subj with behavioral folder and 64 total subjects listed in the subjects directory

!ls -d /import/monstrum/grmpy/subjects/*_*/behavioral/neuroec/ITC*.txt >> Riskfilenames.txt
%for grmpy gets ITC for 62 of 63 subj with behavioral folder and 64 total subjects listed in the subjects directory

%“version 2 risk” (out of scanner CNB task - there is no loss version of this). 
%THIS IS NOT ON MONSTRUM, EXISTS FOR PNC and NEFF (krdisc variable I think), NEEDS TO COME FROM SEPARATE DATA PULL
end