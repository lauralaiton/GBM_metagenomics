import pandas as pd
from matplotlib_venn import venn3, venn3_circles
from matplotlib import pyplot as plt
import matplotlib.patches as patches

df=pd.read_csv('feature-table_final.csv')
df2=df[['Mature-1', 'Mature-2', 'Mature-3', 'Mature-4']] # dataframe only with Mature 
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
	count_Mature_4=0
	count_Mature_12=0
	count_Mature_13=0
	count_Mature_14=0
	count_Mature_23=0
	count_Mature_24=0
	count_Mature_34=0
	count_Mature_123=0
	count_Mature_124=0
	count_Mature_234=0
	count_Mature_134=0
	count_Mature_1234=0
	for i in range(len(df)):
		if df['Mature-1'][i]>0 and df['Mature-2'][i]==0 and df['Mature-3'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_1+=1
		elif df['Mature-2'][i]>0 and df['Mature-1'][i]==0 and df['Mature-3'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_2+=1
		elif df['Mature-3'][i]>0 and df['Mature-1'][i]==0 and df['Mature-2'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_3+=1
		elif df['Mature-4'][i]>0 and df['Mature-1'][i]==0 and df['Mature-2'][i]==0 and df['Mature-3'][i]==0:
			count_Mature_4+=1
		elif df['Mature-1'][i]>0 and df['Mature-2'][i]>0 and df['Mature-3'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_12+=1
		elif df['Mature-1'][i]>0 and df['Mature-3'][i]>0 and df['Mature-2'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_13+=1
		elif df['Mature-1'][i]>0 and df['Mature-4'][i]>0 and df['Mature-2'][i]==0 and df['Mature-3'][i]==0:
			count_Mature_14+=1
		elif df['Mature-2'][i]>0 and df['Mature-3'][i]>0 and df['Mature-1'][i]==0 and df['Mature-4'][i]==0:
			count_Mature_23+=1
		elif df['Mature-2'][i]>0 and df['Mature-4'][i]>0 and df['Mature-1'][i]==0 and df['Mature-3'][i]==0:
			count_Mature_24+=1
		elif df['Mature-3'][i]>0 and df['Mature-4'][i]>0 and df['Mature-2'][i]==0 and df['Mature-1'][i]==0:
			count_Mature_34+=1
		elif df['Mature-1'][i]>0 and df['Mature-2'][i]>0 and df['Mature-3'][i]>0 and df['Mature-4'][i]==0:
			count_Mature_123+=1
		elif df['Mature-1'][i]>0 and df['Mature-2'][i]>0 and df['Mature-4'][i]>0 and df['Mature-3'][i]==0:
			count_Mature_124+=1
		elif df['Mature-3'][i]>0 and df['Mature-2'][i]>0 and df['Mature-4'][i]>0 and df['Mature-1'][i]==0:
			count_Mature_234+=1
		elif df['Mature-3'][i]>0 and df['Mature-1'][i]>0 and df['Mature-4'][i]>0 and df['Mature-2'][i]==0:
			count_Mature_134+=1
		elif df['Mature-3'][i]>0 and df['Mature-1'][i]>0 and df['Mature-4'][i]>0 and df['Mature-2'][i]>0:
			count_Mature_1234+=1
	return(count_Mature_1,count_Mature_2,count_Mature_3,count_Mature_4,count_Mature_12,count_Mature_13,count_Mature_14,count_Mature_23,count_Mature_24,count_Mature_34,count_Mature_123,count_Mature_124,count_Mature_234,count_Mature_134,count_Mature_1234)

count_Mature_1,count_Mature_2,count_Mature_3,count_Mature_4,count_Mature_12,count_Mature_13,count_Mature_14,count_Mature_23,count_Mature_24,count_Mature_34,count_Mature_123,count_Mature_124,count_Mature_234,count_Mature_134,count_Mature_1234 = count(df2)

def draw_ellipse(fig, ax, x, y, w, h, a, fillcolor):
    e = patches.Ellipse(
        xy=(x, y),
        width=w,
        height=h,
        angle=a,
        color=fillcolor,
        alpha=0.5)
    ax.add_patch(e)

def draw_text(fig, ax, x, y, text, color=[0, 0, 0, 1], fontsize=14, ha="center", va="center"):
    ax.text(
        x, y, text,
        horizontalalignment=ha,
        verticalalignment=va,
        fontsize=fontsize,
        color="black")

def venn4(names=['A', 'B', 'C', 'D']):
    """
    plots a 4-set Venn diagram
    @type labels: dict[str, str]
    @type names: list[str]
    @rtype: (Figure, AxesSubplot)
    input
      labels: a label dict where keys are identified via binary codes ('0001', '0010', '0100', ...),
              hence a valid set could look like: {'0001': 'text 1', '0010': 'text 2', '0100': 'text 3', ...}.
              unmentioned codes are considered as ''.
      names:  group names
      more:   colors, figsize, dpi, fontsize
    return
      pyplot Figure and AxesSubplot object
    """
    #colors = options.get('colors', [default_colors[i] for i in range(4)])
    figsize = (12, 12)
    dpi = 96
    fontsize = 28

    fig = plt.figure(0, figsize=figsize, dpi=dpi)
    ax = fig.add_subplot(111, aspect='equal')
    ax.set_axis_off()
    ax.set_ylim(bottom=0.0, top=1.0)
    ax.set_xlim(left=0.0, right=1.0)
    ax.patch.set_alpha(0.5)

    # body
    draw_ellipse(fig, ax, 0.350, 0.400, 0.72, 0.45, 140.0, '#fde725')
    draw_ellipse(fig, ax, 0.450, 0.500, 0.72, 0.45, 140.0, '#440154')
    draw_ellipse(fig, ax, 0.544, 0.500, 0.72, 0.45, 40.0, '#365c8d')
    draw_ellipse(fig, ax, 0.644, 0.400, 0.72, 0.45, 40.0, '#1fa187')
    draw_text(fig, ax, 0.85, 0.42, count_Mature_4, fontsize=fontsize)
    draw_text(fig, ax, 0.68, 0.72, count_Mature_3, fontsize=fontsize)
    draw_text(fig, ax, 0.77, 0.59, count_Mature_34, fontsize=fontsize)
    draw_text(fig, ax, 0.32, 0.72, count_Mature_2, fontsize=fontsize)
    draw_text(fig, ax, 0.71, 0.30, count_Mature_24, fontsize=fontsize)
    draw_text(fig, ax, 0.50, 0.66, count_Mature_23, fontsize=fontsize)
    draw_text(fig, ax, 0.65, 0.50, count_Mature_234, fontsize=fontsize)
    draw_text(fig, ax, 0.14, 0.42, count_Mature_1, fontsize=fontsize)
    draw_text(fig, ax, 0.50, 0.17, count_Mature_14, fontsize=fontsize)
    draw_text(fig, ax, 0.29, 0.30, count_Mature_13, fontsize=fontsize)
    draw_text(fig, ax, 0.39, 0.24, count_Mature_134, fontsize=fontsize)
    draw_text(fig, ax, 0.23, 0.59, count_Mature_12, fontsize=fontsize)
    draw_text(fig, ax, 0.61, 0.24, count_Mature_124, fontsize=fontsize)
    draw_text(fig, ax, 0.35, 0.50, count_Mature_123, fontsize=fontsize)
    draw_text(fig, ax, 0.50, 0.38, count_Mature_1234, fontsize=fontsize)

    # legend
    draw_text(fig, ax, 0.13, 0.18, names[0], '#fde725', fontsize=fontsize, ha="right")
    draw_text(fig, ax, 0.18, 0.83, names[1], '#440154', fontsize=fontsize, ha="right", va="bottom")
    draw_text(fig, ax, 0.82, 0.83, names[2], '#365c8d', fontsize=fontsize, ha="left", va="bottom")
    draw_text(fig, ax, 0.87, 0.18, names[3], '#1fa187', fontsize=fontsize, ha="left", va="top")
    #leg = ax.legend(names, loc='center left', bbox_to_anchor=(1.0, 0.5), fancybox=True)
    #leg.get_frame().set_alpha(0.5)

    return fig, ax

labels={}
fig, ax= venn4(names=['Mature-1', 'Mature-2', 'Mature-3', 'Mature-4'])
fig.savefig("output_Mature2.tif") 











