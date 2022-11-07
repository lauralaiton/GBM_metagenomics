import pandas as pd
from matplotlib import pyplot as plt
from matplotlib_venn import venn3, venn3_circles

df=pd.read_csv('feature-table_final.csv')
df2=df[['Immature-1', 'Immature-2', 'Immature-3']] # dataframe only with Immature 
def count(df):
	'''
	This function counts how many characteristics are unique for every group. 
	And which characteristics are sharing
	Input: DataFrame
	Return: count_Immature_1,count_Immature_2,count_Immature_3, number of characteristics that is present only in one group
			count_Immature_12,count_Immature_13,count_Immature_23, number of characteristics that is present in both groups
			count_Immature_123, number of characteristics that is present in the three groups
	'''
	count_Immature_1=0
	count_Immature_2=0
	count_Immature_3=0
	count_Immature_12=0
	count_Immature_13=0
	count_Immature_23=0
	count_Immature_123=0
	for i in range(len(df)):
		if df['Immature-1'][i]>0 and df['Immature-2'][i]==0 and df['Immature-3'][i]==0:
			count_Immature_1+=1
		elif df['Immature-2'][i]>0 and df['Immature-1'][i]==0 and df['Immature-3'][i]==0:
			count_Immature_2+=1
		elif df['Immature-3'][i]>0 and df['Immature-1'][i]==0 and df['Immature-2'][i]==0:
			count_Immature_3+=1
		elif df['Immature-1'][i]>0 and df['Immature-2'][i]>0 and df['Immature-3'][i]==0:
			count_Immature_12+=1
		elif df['Immature-1'][i]>0 and df['Immature-3'][i]>0 and df['Immature-2'][i]==0:
			count_Immature_13+=1
		elif df['Immature-2'][i]>0 and df['Immature-3'][i]>0 and df['Immature-1'][i]==0:
			count_Immature_23+=1
		elif df['Immature-2'][i]>0 and df['Immature-3'][i]>0 and df['Immature-1'][i]>0:
			count_Immature_123+=1
	return(count_Immature_1,count_Immature_2,count_Immature_3,count_Immature_12,count_Immature_13,count_Immature_23,count_Immature_123)

count_Immature_1,count_Immature_2,count_Immature_3,count_Immature_12,count_Immature_13,count_Immature_23,count_Immature_123 = count(df2)

out = venn3(subsets = (count_Immature_1, count_Immature_2, count_Immature_12, count_Immature_3,count_Immature_13,count_Immature_23,count_Immature_123), set_labels = ('Immature-1', 'Immature-2', 'Immature-3'),
    set_colors=('#22a884', '#fde725','#440154'))# this function create the graphic
for text in out.set_labels:
   text.set_fontsize(14)

for text in out.subset_labels:
   text.set_fontsize(14)

plt.savefig("output_Immature2.tif") # save the graphic in TIFF format
