#!/usr/bin/env bash

declare -A color_values;

color_values[amber]="#ffa000";
color_values[black]="#000407";
color_values[blue]="#0000ff";
color_values[brown]="#a52a2a";
color_values[green]="#00d400";
color_values[grey]="#808080";
color_values[magenta]="#f000f0";
color_values[orange]="#ffa500";
color_values[pink]="#ffc0cb";
color_values[red]="#d40000";
color_values[violet]="#ee82ee";
color_values[white]="#ffffff";
color_values[yellow]="#ffd400";

names=('barrel' 'buoyant' 'cairn' 'can' 'conical' 'pillar' 'spar' 'spherical' 'stake' 'super-buoy' 'tower')

for name in "${names[@]}"; do
  while read -r pattern colorstring; do

    colors=($colorstring)

    if [[ "$pattern" == "solid" ]]; then
      filename="svgs/$name/${colorstring// /_}.svg";
      prefix="h";
    else
      filename="svgs/$name/$pattern/${colorstring// /_}.svg";
      prefix=${pattern:0:1};
    fi

    echo "generating $filename";

    
    actions="";
    for ((i=0; i<${#colors[@]}; i++)); do
      fraction=$(( (i + 1) * 12 / ${#colors[@]} ))
      id="path_fill_${prefix}${fraction}";
      if [[ "${colors[i]}" != "generic" ]]; then
        color_value=${color_values[${colors[i]}]};
        actions="${actions}select-clear;select-by-id:$id;object-set-attribute:style,fill:${color_value};";
      fi
    done

    inkscape \
      --actions="$actions" \
      --export-plain-svg --export-filename="$filename" \
      "svgs/$name/base.svg"
  done < "svgs/$name/colors.txt"

  # Generate Topmarks:
  width=$(xmlstarlet sel -t -v "/_:svg/@width" "svgs/$name/base.svg")
  height=$(xmlstarlet sel -t -v "/_:svg/@height" "svgs/$name/base.svg")
  exec 3< "svgs/$name/topmarks.txt"
  read -r x_shift y_shift rotation <&3
  while read -r shape pattern colorstring; do
    colors=($colorstring)

    if [[ "$pattern" == "solid" ]]; then
      filename="svgs/$name/topmark/$shape/${colorstring// /_}.svg";
      prefix="h";
    else
      filename="svgs/$name/topmark/$shape/$pattern/${colorstring// /_}.svg";
      prefix=${pattern:0:1};
    fi

    echo "generating $filename";

    width_topmark=$(xmlstarlet sel -t -v "/_:svg/@width" "generator/topmark/$shape.svg")
    height_topmark=$(xmlstarlet sel -t -v "/_:svg/@height" "generator/topmark/$shape.svg")
    
    x_shift2=$(echo "$x_shift $width $width_topmark" | awk '{printf "%f", $1 + ($2/2) - ($3/2)}'  )
    y_shift2=$(echo "$y_shift $height $height_topmark" | awk '{printf "%f", $1 + $2 - $3}'  )
    actions="select-all;transform-translate:$x_shift2,$y_shift2;transform-rotate:$rotation;";
    for ((i=0; i<${#colors[@]}; i++)); do
      fraction=$(( (i + 1) * 12 / ${#colors[@]} ))

      # Special case for border with only two colors
      if [[ "$pattern" == "border" && ${#colors[@]} == 2 && $i == 0 ]]; then
        fraction="2";
      fi

      id="path_fill_${prefix}${fraction}";
      if [[ "${colors[i]}" != "generic" ]]; then
        color_value=${color_values[${colors[i]}]};
        actions="${actions}select-clear;select-by-id:$id;object-set-attribute:style,fill:${color_value};";
      fi
    done

    inkscape \
      --actions="$actions" \
      --export-plain-svg --export-filename="$filename" \
      "generator/topmark/$shape.svg"
    
    xmlstarlet ed -L \
      -u "/_:svg/@width" -v "$width" \
      -u "/_:svg/@height" -v "$height" \
      "$filename"
  done <&3;

done