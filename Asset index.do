*This data set comes from the Ethiopian Rural Socioeconomic Survey 
version  13.1
clear all
set more off
global   raw    "C:\Users\Fitsum\Dropbox\Staples Calorie Approach\data\raw"
global   final  "C:\Users\Fitsum\Dropbox\Staples Calorie Approach\data\final"
global	 calconv "C:\Users\Fitsum\Dropbox\Staples Calorie Approach\calories conversion"
********************************************************************
*                          Asset Index
********************************************************************
*** Livestock ***
tempfile livestock
	use "$raw\sect8a_ls_w1.dta", clear
	keep holder_id-ls_s8aq00 ls_s8aq13a ls_s8aq26- ls_s8aq28
	g beehive= ls_s8aq26+ ls_s8aq27+ ls_s8aq28
		la var beehive "Total number of beehives"
	drop ls_s8aq26 ls_s8aq27 ls_s8aq28 beehive
	drop if  ls_s8aq00==.
	reshape wide ls_s8aq13a, i( holder_id ) j( ls_s8aq00 )
	rename (ls_s8aq13a1 ls_s8aq13a2 ls_s8aq13a3 ls_s8aq13a4 ls_s8aq13a5 ///
			ls_s8aq13a6 ls_s8aq13a7 ls_s8aq13a8 ls_s8aq13a9 ls_s8aq13a10 ///
			ls_s8aq13a11 ls_s8aq13a12 ls_s8aq13a13 ls_s8aq13a14) ///
			(cattle sheep goats horses donkeys mules camels laying_hens ///
			nonlaying_hens cocks cockerels pullets chicks beehives)
	order holder_id household_id- ls_saq07
	drop beehives
	recode cattle .=0
	recode sheep .=0
	recode goats .=0
	recode horses .=0
	recode donkeys .=0
	recode mules .=0
	recode camels .=0
	recode laying_hens .=0
	recode nonlaying_hens .=0
	recode cocks .=0
	recode cockerels .=0
	recode pullets .=0
	recode chicks .=0
	g tlu=0.7*cattle+0.1*sheep+0.1*goats+0.8*horses+0.5*donkeys+0.5*mules+ ///
		1.0*camels+0.01*(laying_hens+nonlaying_hens+cocks+cockerels+pullets+chicks)
	collapse (sum) tlu, by( household_id)
	la var tlu "livestock in tropical livestock units"
save "`livestock'",replace
	
*** HH Assets ***
tempfile asset
	use "$raw\sect10_hh_w1.dta", clear
	drop hh_s10q0a hh_s10q02_a hh_s10q02_b
	reshape wide hh_s10q01, i( household_id ) j( hh_s10q00 )
		order household_id ea_id rural pw saq01 saq02 saq03 saq04 saq05 saq06 saq07 saq08
	rename (hh_s10q011- hh_s10q0135) ///
	(kerosene_stove butane_stove electric_stove blanket_gabi bed watch telephone ///
	mobile radio television vcd dish sofa bicycle motorcycle cart_hand cart_animal ///
	sewing weaving mitad_electric mitad_powersaving refridgerator car jewels ///
	wardrobe shelf biogas_stove water_pit mofer_kember sickle axe pick_axe ///
	plough_traditional plough_modern water_pump)
#d ;
	global asset "kerosene_stove butane_stove electric_stove blanket_gabi bed 
	watch telephone mobile radio television vcd dish sofa bicycle motorcycle 
	cart_hand cart_animal sewing weaving mitad_electric mitad_powersaving 
	refridgerator car jewels wardrobe shelf biogas_stove water_pit 
	mofer_kember sickle axe pick_axe plough_traditional plough_modern water_pump";
#d cr ;
save "`asset'",replace

*** Housing ***
tempfile housing
	use "$raw\sect9_hh_w1.dta", clear
	merge 1:1 household_id using "$final\hhsize_adult_equiv.dta"
		drop _m
	g person_room=hh_size/hh_s9q04
		la var person_room "number of person per room"
	recode hh_s9q05 1/3 10=1 4/9=3 11/17=2 *=.
		la def wall 1"mud/wood" 2"steel/bamboo" 3"stone/block"
		la val hh_s9q05 wall
	recode hh_s9q06 3/7=1 1 2 8=2 *=.
		la def roof 1"tach/wood/mud" 2"ironsheet/concrete"
		la val hh_s9q06 roof
	recode hh_s9q07 1=0 *=1
		la var hh_s9q07 "not mud floor"
		la def yes 1"yes" 0"no"
		la val hh_s9q07 yes
	recode hh_s9q10 8=0 *=1
		la var hh_s9q10 "has toilet"
		la val hh_s9q10 yes
	recode hh_s9q13  1/7=1 *=0
		la var hh_s9q13 "improved water rainy season"
	recode hh_s9q14  1/7=1 *=0
		la var hh_s9q14 "improved water dry season"
		la val hh_s9q13 hh_s9q14 yes
	recode hh_s9q21 1/6=1 7 8=2 9/11=3 *=.
		la def fuel 1"wood/charcoal" 2"focil fue" 3"elec/solar"
		la val hh_s9q21 fuel 
#d ;
	global housing "person_room hh_s9q05 hh_s9q06 hh_s9q07 hh_s9q10 hh_s9q13
		hh_s9q14 hh_s9q21";
#d cr ;
save "`housing'",replace

********************************************************************
*                                  Merging 
********************************************************************
use "`livestock'",clear
merge 1:1 household_id using "`asset'"
	drop _m
	recode tlu .=0
merge 1:1 household_id using "`housing'"
	drop _m
pca $housing $asset tlu
	estat kmo
	predict index
	xtile asset=index, nq(5)
keep household_id ea_id- saq08 asset
save "$final\asset.dta",replace
