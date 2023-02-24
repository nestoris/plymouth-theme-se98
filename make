#!/usr/bin/awk -f
BEGIN{
	basebuildfld=buildfld="se98"
	srcdir="src"
	file_in=srcdir"/base.svg"
	file_out="logon.png"
	spinner_in=srcdir"/gradient.svg"
	spinnerbase="gradient_"
	basescript=srcdir"/base.script"
	logout_out=srcdir"/w95_shutdown.png"

	spindir="-" # (- <-) (+ ->)


	printf " Getting"(ARGC>2?" "ARGC-1" ":" ")"screen resolution"(ARGC>2?"s":"")"..."
	for(fl=1;fl<ARGC;fl++){
		if(ARGV[fl]~/^[0-9]+x[0-9]+$/){
			resols[ARGV[fl]]=ARGV[fl]
		}
	}
	if(resols[ARGV[1]]){
		for(fl in resols){
			scrr=resols[fl]
			ARGC>2?buildfld=basebuildfld"_"resols[fl]:""

			system("mkdir -p "ENVIRON["PWD"]"/"buildfld)
			close("mkdir -p  "ENVIRON["PWD"]"/"buildfld)
			script_out=buildfld "/se98.script"
			logfile=buildfld "/make.log"

			run_for_res(scrr)
		}
	}else{
		scrr=screenres()

		system("mkdir -p "ENVIRON["PWD"]"/"buildfld)
		close("mkdir -p  "ENVIRON["PWD"]"/"buildfld)
		script_out=buildfld "/se98.script"
		logfile=buildfld "/make.log"

		run_for_res(scrr)
	}
}

function run_for_res(scrr){

print "  " scrr
print "Screen: "scrr > logfile
split(scrr,scra,"x")

printf " Getting dimentions of \""file_in"\"..."
size_svg(file_in,sizes)
print " "sizes["w"]"x"sizes["h"]
print "SVG source file: "file_in", "sizes["w"]"x"sizes["h"] > logfile

build(file_in,buildfld,file_out,scra[1],scra[2],sizes["w"],sizes["h"])

}

function l_s(string){
print string > logfile
}

function size_svg(file,res,		u,cmd){ # узнать размеры векторной картинки, получить массив с элементами "w" и "h".
	cmd="inkscape -W -H " file
	while((cmd|getline)>0){
		u=(u?"h":"w") # сперва идёт ширина, потом высота
		res[u]=$0
		if(!$0>0){exit}
	}
	close(cmd)
}


function screenres(){
	cmd="find /sys/class/drm/*/ -name \"modes\" -exec cat {} \\;"
	while((cmd|getline)>0){
		if($0 in was){
		}else{
			out=(f?out:$0)
			$0?f++:""}
			was[$0]
		}
	close(cmd)
	return out
}

function build(file_in,buildfld,file_out,wid_out,hei_out,wid_orig,hei_orig,	cmd1,cmd2,cmd3){ # wid_orig,hei_orig можно не указывать, но тогда каждый раз будет выполняться программа распознавания, а это долго!

	grad_hei=int(hei_out/36)

	if(wid_orig && hei_orig){
		sizes["w"]=wid_orig
		sizes["h"]=hei_orig
	}else{
		size_svg(file_in,sizes)
	}

## Расчёт сдвига
	shift=int((hei_out/sizes["h"]*sizes["w"]-wid_out)/2)

## Команды преобразований
	cmd0="cp "srcdir"/se98.plymouth "buildfld"; cp "srcdir"/box.png "buildfld"; cp "srcdir"/bullet.png "buildfld"; cp "srcdir"/entry.png "buildfld"; cp "srcdir"/lock.png "buildfld"; cp "logout_out" "buildfld
	cmd1="inkscape -h "hei_out" "file_in" -o "buildfld"/"file_out # рендеринг svg с указанием высоты (учитывая, что экраны все горизонтальные)
	cmd2="inkscape -h "grad_hei" -w "wid_out" "spinner_in" -o "buildfld"/gradient_"wid_out"x"hei_out".png"
	cmd3="convert "buildfld"/"file_out" -crop "wid_out"x"hei_out (shift<0?"":"+")shift" "buildfld"/"file_out # обрезка с рассчитанным сдвигом
#	cmd3="convert "buildfld"/"file_out" -crop "wid_out"x"hei_out " -gravity center "file_out # обрезка с притяжением к центру
	cmd4="magick composite -geometry +0+"hei_out-grad_hei" "buildfld"/"spinnerbase wid_out"x"hei_out".png "buildfld"/"file_out" "buildfld"/"file_out"; rm \""buildfld"/"spinnerbase wid_out"x"hei_out".png\""
	cmd5="convert "buildfld"/"file_out" -background \"#A2C5DC\" -gravity center -extent "wid_out"x"hei_out " "buildfld"/"file_out
	print wid_out
	spincount=int(wid_out/80) # количество кадров в зависимости от ширины экрана
	anim_rate=int(48/spincount) # мин. задержка между кадрами
	anim_rate=anim_rate<1?1:anim_rate
	cmd6="for ((i=1; i < "spincount"; i++)); do let \"A=$i*"int(wid_out/spincount)"\" && convert "buildfld"/"spinnerbase wid_out"x"hei_out".png -roll "spindir"${A}+0 "buildfld"/"spinnerbase "${i}.png && echo \"  $i of "spincount"\"; done; mv "buildfld"/"spinnerbase wid_out"x"hei_out".png "buildfld"/"spinnerbase spincount".png && echo \"  "spincount" of "spincount"\"" # делаем кадры анимации
	cmd7="convert "buildfld"/"file_out" -gravity center -extent "wid_out"x"hei_out-grad_hei" "buildfld"/"file_out
	cmd8="convert "buildfld"/"file_out" -background none -extent "wid_out"x"hei_out" "buildfld"/"file_out


## Процесс преобразования
	if(system(cmd0)>0){print "Interrupted.";l_s("Copy interrupted!");exit}else{l_s("Copy done.")}
	printf " Extracting "int(sizes["w"]/sizes["h"]*hei_out)"x"hei_out" image..."
	if(system(cmd1)>0){print "Interrupted.";l_s("Extracting interrupted!");exit}else{l_s("Extracting done.")}
	printf " Creating stripe "wid_out"x"grad_hei"..."
	if(system(cmd2)>0){print "Interrupted.";l_s("Creating stripe interrupted!");exit}else{l_s("Creating stripe done.")}
	if(int(sizes["w"]/sizes["h"]*hei_out)<wid_out){
		printf " Extending to "wid_out"..."
		if(system(cmd5)>0){print "Interrupted.";l_s("Extending to "wid_out" interrupted!");exit}else{l_s("Extending to "wid_out" done.")}
	}else {if(wid_out!=int(sizes["w"]/sizes["h"]*hei_out)){
		printf " Cropping to "wid_out"x"hei_out"..."
		if(system(cmd3)>0){print "Interrupted.";l_s("Cropping to "wid_out"x"hei_out" interrupted!");exit}else{l_s("Cropping to "wid_out"x"hei_out" done.")}
	}}
	print " Creating frames for animation..."
	if(system(cmd6)>0){print "Interrupted.";l_s("Creating frames interrupted!");exit}else{l_s("Creating frames done.")}
	print " Cutting "grad_hei" px from bottom for throbber..."
	if(system(cmd7)>0){print "Interrupted.";l_s("Cutting "grad_hei" px from bottom interrupted!");exit}else{l_s("Cutting "grad_hei" px from bottom done.")}
	print " Extending bottom back to "wid_out"x"hei_out"..."
	if(system(cmd8)>0){print "Interrupted.";l_s("Extending bottom back to "wid_out"x"hei_out" interrupted!");exit}else{l_s("Extending bottom back to "wid_out"x"hei_out" done.")}

## Правим скрипт
	while((getline < basescript)>0){
		gsub("%BOOT%", "\""file_out"\"")
		gsub("%SHUTDOWN%", "\""logout_out"\"")
		gsub("%SPINNERBASE%", "\""spinnerbase"\"")
		gsub("%PROGRESS%", spincount-1)
		gsub("%RATE%", anim_rate)
		print > script_out
	}

## Compiling boot splash packer.
#	cmdb="gcc -o "buildfld"/bootsplash-packer bootsplash-packer.c; chmod +x "buildfld"/bootsplash-packer"
#	system(cmdb)
#	close(cmdb)

## Creating boot splash.
#	cmdc="mogrify -format rgb *.png && "buildfld"/bootsplash-packer --bg_red 0xA2 --bg_green 0xC5 --bg_blue 0xDC --frame_ms "msec" --picture --pic_width "wid_out" --pic_height "hei_out" --pic_position 0x00 --pic_anim_type 0 --blob "buildfld"/"gensub(/png$/,"rgb",1,file_out)" --picture --pic_width "wid_out" --pic_height "grad_hei" --pic_position 0x05 --pic_anim_type 1 --pic_anim_loop 0"
#	for(i=1;i<=spincount;i++){cmdc=cmdc " --blob gradient_"i".rgb" }
#	cmdc=cmdc " se98"
#	system(cmdc)
#	close(cmdc)
#	printf " Наклейка полосы..."; if(system(cmd4)>0){print "Прервано.";exit}
	#printf " Удаление полосы..."

	close(cmd1)
	close(cmd0)
	close(cmd2)
	close(cmd3)
	close(cmd5)
#	close(cmd4)
	close(cmd6)
	close(cmd7)
	if(close(cmd8)<0){print " Done!\n\nTO INSTALL THIS THEME IN "wid_out"x"hei_out" RESOLUTION RUN THESE COMMANDS:\n\tsudo cp -r \""ENVIRON["PWD"]"/"buildfld"\" /usr/share/plymouth/themes\n\tsudo plymouth-set-default-theme -R "buildfld"\nTO PREVIEW BOOT SCREEN RUN:\n\tsudo ./test-plymouth";l_s("\nAll OK!")}
}




