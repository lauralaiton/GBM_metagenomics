import pandas as pd
from matplotlib_venn import venn2, venn2_circles, venn2_unweighted
from matplotlib import pyplot as plt

df=pd.read_csv('feature-table_final.csv')

df2=pd.DataFrame() # se crea un nuevo DataFrame donde almacenaremos las sumas de las columnas Immature y Mature
df2['immature']= df[['Immature-1','Immature-2','Immature-3','Immature-4' ]].sum(axis=1)
df2['mature']= df[['Mature-1','Mature-2','Mature-3']].sum(axis=1)

def count(df):
	'''
	This function counts how many characteristics are unique for mature, and immature. 
	And which characteristics are sharing
	Input: DataFrame
	Return: count_mature, number of characteristics that is present only in matures
			count_immature, number of characteristics that is present only in immatures
			count_no, number of characteristics that is present in both
	'''
	count_mature=0
	count_immature=0
	count_no=0
	for i in range(len(df)):
		if df.mature[i]>0 and df.immature[i]==0:
			count_mature+=1
		elif df.mature[i]==0 and df.immature[i]>0:
			count_immature+=1
		else:
			count_no+=1
	return(count_mature,count_immature,count_no)

count_mature,count_immature,count_no = count(df2) #apply the function

out = venn2(subsets = (count_mature,count_immature,count_no ), set_labels = ('Mature', 'Immature'),
	set_colors=('#3b528b', '#5ec962')) # this function create the graphic
for text in out.set_labels:
   text.set_fontsize(16)

for text in out.subset_labels:
   text.set_fontsize(16)

plt.savefig("output1.tif") # save the graphic in TIFF format