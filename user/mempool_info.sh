#!/bin/bash

#-----------------------------------------------------------------
# source/read config from repository
. <(curl -sL https://github.com/BtcAutoNode/BtcAutoNode/raw/master/CONFIG)
# or if you changed anything the config, copy CONFIG to here and comment out above line and uncomment the next line
#. CONFIG
#-----------------------------------------------------------------

# exit if mempool is not available
if ! (exec 3<>/dev/tcp/"localhost"/"8999") &>/dev/null; then
    echo
    echo -e "  ${R}Mempool cannot be reached...is mempool running? Exiting${NC}"
    exit
fi


url="https://${LOCAL_IP}:${MEMPOOL_SSL_PORT}"
bo="\033[1m" # bold text

function get_block() {
   local block_height=$1
   block_hash=$(curl -ksSL "${url}/api/block-height/${block_height}")
   #---------------------------------------------------------------------------------
   block=$(curl -ksSL "${url}/api/block/${block_hash}")
   block_tx_count=$(echo "${block}" | jq -r ".tx_count")
   block_size=$(echo "${block}" | jq -r ".size")
   #---------------------------------------------------------------------------------
   block_timestamp=$(echo "${block}" | jq -r ".timestamp")
   current_timestamp=$(date +%s)
   time_diff=$(("${current_timestamp}" - "${block_timestamp}"))
   #---------------------------------------------------------------------------------
   block_median_fee=$(echo "${block}" | jq -r ".extras.medianFee")
   block_fee_range=$(echo "${block}" | jq -cr ".extras.feeRange")
   fee_min=$(echo "${block_fee_range}" | cut -d',' -f2)
   fee_max=$(echo "${block_fee_range}" | cut -d',' -f7 | cut -d']' -f1)
   #---------------------------------------------------------------------------------

   blkmedfee=$(printf "     % 2s sat/vB\n" "$block_median_fee")
   feerange=$(printf "  % 3s-%s sat/vB\n" "${fee_min}" "${fee_max}")
   blksize=$(echo "${block_size}" | awk '{$1/=1000*1000;printf "     % 3.2f MB\n",$1}')
   txs=$(printf " % 3s transactions\n" "$block_tx_count")
   mins=$(printf "  % 2s minute(s) ago\n" $(("${time_diff}" / 60)))
   echo -e "${LB} --------------------${NC}\n" \
           "${CY}${bo}       ${block_height}${NC}\n" \
           "${LB}--------------------${NC}\n" \
           "${blkmedfee}\n" \
           "${BR}${feerange}${NC}\n" \
           "${bo}${blksize}${NC}\n" \
           "${txs}\n" \
           "${mins}\n" \
           "${LB}--------------------${NC}"
}

#---------------------------------------------------------------------------------
#mempool=$(curl -ksSL "${url}/mempool")
#mempool_tx_count=$(echo "${mempool}" | jq -r '.count')
#---------------------------------------------------------------------------------

# main
clear
# get block tip height (newest block), then the 5 blocks before
block_tip_height=$(curl -ksSL "${url}/api/blocks/tip/height")
block1=$(get_block "$block_tip_height")
block2=$(get_block $(("$block_tip_height" - 1)))
block3=$(get_block $(("$block_tip_height" - 2)))
block4=$(get_block $(("$block_tip_height" - 3)))
block5=$(get_block $(("$block_tip_height" - 4)))
block6=$(get_block $(("$block_tip_height" - 5)))
# output all blocks in one row
sep=" "
echo
echo -e "${LB}------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo
echo -e "${LG}  Latest Blocks:${NC}"
paste <(echo -e "$block1") <(echo -e "$block2") <(echo -e "$block3") <(echo -e "$block4") <(echo -e "$block5") <(echo -e "$block6") | column -o "$sep" -s $'\t' -t
echo

# recommended fees
recommended_fees=$(curl -ksSL "${url}/api/v1/fees/recommended")
#recom_fee_min=$(echo "${recommended_fees}" | jq -r ".minimumFee")
recom_fee_eco=$(echo "${recommended_fees}" | jq -r ".economyFee")
recom_fee_hour=$(echo "${recommended_fees}" | jq -r ".hourFee")
recom_fee_half=$(echo "${recommended_fees}" | jq -r ".halfHourFee")
recom_fee_fast=$(echo "${recommended_fees}" | jq -r ".fastestFee")
sep="                   "
echo -e "${LG}  Transaction Fees:${NC}"
paste <(echo -e "${LB}   No Priority: \n    ${bo}${recom_fee_eco} sat/vB") <(echo -e "Low Priority: \n ${recom_fee_hour} sat/vB") <(echo -e "Med. Priority: \n  ${recom_fee_half} sat/vB") <(echo -e "High Priority:${NC} \n  ${recom_fee_fast} sat/vB")| column -o "$sep" -s $'\t' -t
echo
echo -e "${LB}------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo

# difficulty
difficulty=$(curl -ksSL "${url}/api/v1/difficulty-adjustment")
#-----------------------------
#diff_percent=$(echo "${difficulty}" | jq -r ".progressPercent" | xargs printf "%.2f\n")
diff_exp_blocks=$(echo "${difficulty}" | jq -r ".expectedBlocks" | xargs printf "%.0f\n")
#diff_rem_blocks=$(echo "${difficulty}" | jq -r ".remainingBlocks" | xargs printf "%.0f\n")
#-----------------------------
diff_est_date=$(echo "${difficulty}" | jq -r ".estimatedRetargetDate")
len="${#diff_est_date}"; to=$(("${len}" - 3))
diff_est_date="${diff_est_date:0:$to}"."${diff_est_date:$to:$len}"
est_date=$(date -d @"$diff_est_date" '+%b %d at %H:%M')
#-----------------------------
#diff_prev_time=$(echo "${difficulty}" | jq -r ".previousTime")
#prev_time=$(date -d @"$diff_prev_time" '+%b %d at %H:%M')
#-----------------------------
diff_avg_blktime=$(echo "${difficulty}" | jq -r ".timeAvg")
diff_avg_blktime="${diff_avg_blktime:0:3}"."${diff_avg_blktime:3:6}"
avg_blktime=$(bc -l <<< "${diff_avg_blktime}/60" | xargs printf "%.2f\n")
#-----------------------------
diff_rem_time=$(echo "${difficulty}" | jq -r ".remainingTime")
len="${#diff_rem_time}"; to=$(("${len}" - 3))
diff_rem_time="${diff_rem_time:0:$to}"."${diff_rem_time:$to:$len}"
rem_time=$(bc -l <<< "${diff_rem_time}/60/60/24" | xargs printf "%.2f\n")
#-----------------------------
diff_change=$(echo "${difficulty}" | jq -r ".difficultyChange")
comp=$(echo "$diff_change < 0" | bc)
if [ "$comp" = "1" ]; then
    change=$(echo "$diff_change" | xargs printf "${R}%.2f${NC}\n")
else
    change=$(echo "$diff_change" | xargs printf "${G}%.2f${NC}\n")
fi
#-----------------------------
diff_prev_retarget=$(echo "${difficulty}" | jq -r ".previousRetarget")
comp=$(echo "$diff_prev_retarget < 0" | bc)
if [ "$comp" = "1" ]; then
    prev_retarget=$(echo "$diff_prev_retarget" | xargs printf "${R}%.2f${NC}\n")
else
    prev_retarget=$(echo "$diff_prev_retarget" | xargs printf "${G}%.2f${NC}\n")
fi
#-----------------------------

# difficulty progress bar
function show_progress {
   bar_size=110; bar_char_done="#"; bar_char_todo="-"; bar_percentage_scale=2
   current="$1"
   total="$2"
   # calculate the progress in percentage
   percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
   # The number of done and todo characters
   done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
   todo=$(bc <<< "scale=0; $bar_size - $done" )
   # build the done and todo sub-bars
   done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
   todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")
   # output the bar
   echo -ne "${LB}\r   [${done_sub_bar}${todo_sub_bar}] ${percent}%\n${NC}"
}

echo -e "${LG}  Difficulty Adjustment:${NC}"
show_progress "$diff_exp_blocks" "2016"
echo -e "                    ${bo}~${avg_blktime} minutes                     ${change} %                     In ~${rem_time} days${NC}"
echo -e "                    Average block time             Previous: ${prev_retarget} %               ${est_date}"
echo
echo -e "${LB}------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo

