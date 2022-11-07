import pandas as pd
from matplotlib_venn import venn3, venn3_circles
from matplotlib import pyplot as plt

df=pd.read_csv('feature-table_final.csv')
df2=df[['Mature-1', 'Mature-2', 'Mature-3']] # dataframe only with Mature 
def count(df):
	'''
	This function counts how many characteristics are unique for every group. 
	And which characteristics are sharing
	Input: DataFrame
	Return: count_Mature_1,count_Mature_2,count_Mature_3, number of characteristics that is present only in one group
			count_Mature_12,count_Mature_13,count_Mature_23, number of characteristics that is present in both groups
			count_Mature_123, number of characteristics that is present in the three groups
	'''
	count_Mature_1=0
	count_Mature_2=0
	count_Mature_3=0
	count_Mature_12=0
	count_Mature_13=0
	count_Mature_23=0
	count_Mature_123=0
	for i in range(len(df)):
		if df['Mature-1'][i]>0 and df['Mature-2'][i]==0 and df['Mature-3'][i]==0:
			count_Mature_1+=1
		elif df['Mature-2'][i]>0 and df['Mature-1'][i]==0 and df['Mature-3'][i]==0:
			count_Mature_2+=1
		elif df['Mature-3'][i]>0 and df['Mature-1'][i]==0 and df['Mature-2'][i]==0:
			count_Mature_3+=1
		elif df['Mature-1'][i]>0 and df['Mature-2'][i]>0 and df['Mature-3'][i]==0:
			count_Mature_12+=1
		elif df['Mature-1'][i]>0 and df['Mature-3'][i]>0 and df['Mature-2'][i]==0:
			count_Mature_13+=1
		elif df['Mature-2'][i]>0 and df['Mature-3'][i]>0 and df['Mature-1'][i]==0:
			count_Mature_23+=1
		elif df['Mature-2'][i]>0 and df['Mature-3'][i]>0 and df['Mature-1'][i]>0:
			count_Mature_123+=1
	return(count_Mature_1,count_Mature_2,count_Mature_3,count_Mature_12,count_Mature_13,count_Mature_23,count_Mature_123)

count_Mature_1,count_Mature_2,count_Mature_3,count_Mature_12,count_Mature_13,count_Mature_23,count_Mature_123 = count(df2)
out = venn3(subsets = (count_Mature_1,count_Mature_2,count_Mature_12,count_Mature_3,count_Mature_13,count_Mature_23,count_Mature_123), set_labels = ('Mature-1', 'Mature-2', 'Mature-3'),
	set_colors=('#22a884', '#fde725','#440154'))# this function create the graphic
for text in out.set_labels:
   text.set_fontsize(14)

for text in out.subset_labels:
   text.set_fontsize(14)

plt.savefig("output_Mature.tif") # save the graphic in TIFF format