#!/bin/bash

#------------------------------------------------------------------------------
#	Information
#------------------------------------------------------------------------------

author="James Chan"
email="ccchan0109@gmail.com"
version="1.0.4"
updateDate="2020/11/26"

#------------------------------------------------------------------------------
#	Parameteres
#------------------------------------------------------------------------------

working_root="/svssrc/svs"
project_specified="Surveillance"
platform="x64"
dsm_version="6.2"
projects=(
	"Surveillance"
	"SurvDevicePack"
	"libssmodule"
)

CLEAR=no
ALL_SVS_RELATED=no
INCLUDE_IGNORED=no
INCLUDE_UNTRACKED=no

#------------------------------------------------------------------------------
#	Utils
#------------------------------------------------------------------------------

pushd()
{
	command pushd "$@" > /dev/null
}

popd()
{
	command popd "$@" > /dev/null
}

#------------------------------------------------------------------------------
#	Functions
#------------------------------------------------------------------------------

usage()
{
cat <<EOF
usage: $0 [-a] [-c] [-r] [-i] [-u] [-s] [-x] [-p] [-s] [-v] [-h]

OPTIONS:
	-a		Relink Surveillance related projects
	-c		Clear hard link entire folder by removing the target folder; you may rebuild code
	-r		Relink by examing sperate files, default options
	-i		Ignored files included
	-u		Untracked files included
	-s		Specified project name, default is $project_specified
	-x		Working root path, default is $working_root
	-p		Platform, default is $platform
	-v		DSM version, default is $dsm_version
	-h		Show usage

AUTHOR:
	$author - $email

VERSION:
	$version @ $updateDate

EOF
}

clearRelink()
{
	echo "Clear and Relink..."
	pushd $src_folder
	rm -rf $platform_folder
	cp -al . $platform_folder
	popd
}

relink()
{
	pushd $src_folder

	tracked_files=$(git ls-files)
	untracked_files=$(git ls-files --others --exclude-standard)
	ignored_files=$(git ls-files --others -i --exclude-standard)
	files=$tracked_files

	if [ $INCLUDE_IGNORED == "yes" ]; then
		echo "Include ignored files";
		files="$files $ignored_files";
	fi

	if [ $INCLUDE_UNTRACKED == "yes" ]; then
		echo "Include untracked files";
		files="$files $untracked_files";
	fi

	echo "Begin Relink..."
	count=0
	for new_path in ${files[@]}; do
		if [ ! -f "$new_path" ]; then
			continue;
		fi

		ori_path="$platform_folder$new_path"
		if [ "$ori_path" -ef "$new_path" ]; then
			#hard link existed, do nothing
			continue;
		fi

		dir_path=$(dirname $ori_path)

		if [ ! -d "$dir_path" ]; then
			mkdir -p "$dir_path"
		fi

		echo "relink $new_path to $ori_path"
		if [ -f "$ori_path" ]; then
			rm "$ori_path"
		fi
		ln "$new_path" "$ori_path"
		let count++
	done
	echo "Done for $count files"

	popd
}

main()
{
	while getopts "hrciuas:p:x:v:" OPTION
	do
		case $OPTION in
			h)
				usage
				exit 1
				;;
			r)
				CLEAR=no
				;;
			c)
				CLEAR=yes
				;;
			i)
				INCLUDE_IGNORED=yes
				;;
			u)
				INCLUDE_UNTRACKED=yes
				;;
			a)
				ALL_SVS_RELATED=yes
				;;
			s)
				project_specified=$OPTARG
				;;
			p)
				platform=$OPTARG
				;;
			x)
				working_root=$OPTARG
				;;
			v)
				dsm_version=$OPTARG
				;;
			?)
				usage
				exit 1
				;;
		esac
	done

	if [ $ALL_SVS_RELATED != "yes" ]; then
		projects=($project_specified)
	fi

	for project in ${projects[@]}; do
		if [ ! -d "$project" ]; then
			#User specify the name of project, and we find the path based on working root path
			src_folder="$working_root/source/$project/"
		else
			#User directly specify the project path
			src_folder="$project"
			project=$(basename $project)
		fi

		platform_folder="$working_root/build_env/ds.$platform-$dsm_version/source/$project/"

		if [ ! -d "$src_folder" ]; then
			echo "Source Folder $src_folder not existed"
			continue
		fi

		echo "The relink path is $platform_folder"

		if [ $CLEAR == "yes" ]; then
			read -p "Are you sure you want to clear relink? (y/n): " CONFIRM_CLEAR
			if [ $CONFIRM_CLEAR != "y" ] && [ $CONFIRM_CLEAR != "Y" ]; then
				CLEAR=no
			fi
		fi

		if [ $CLEAR == "yes" ]; then
			clearRelink
		else
			relink
		fi
	done
}

main "$@"
