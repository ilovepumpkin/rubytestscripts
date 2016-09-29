require 'hpricot'
require 'common'

hash_cols=Hash["unattempted"=>1,"blocked"=>2,"attempted"=>3,"failed"=>4,"permfailed"=>6,"completed"=>5,"deferred"=>7]
phase="2.0 FVT Execution"
url="http://9.123.196.12/tr_dir/sh_tr_043/MashupMakerTTT.nsf/a898cb2b86bcb43d482575cc002cb4a0?OpenView"
file_path="mmfvt_er_scurve.csv"

resp=Net::HTTP.get_response(URI.parse(url))
html=resp.body
doc = Hpricot(html)
data_table=doc.search("//table")[1]
tr_list=data_table.search("//tr")
tr_list.each{|tr|
  if tr.inner_html.index(phase)!=nil
    td_list=tr.search("//td")
    unattempted=td_list[hash_cols["unattempted"]].inner_text.to_i
    blocked=td_list[hash_cols["blocked"]].inner_text.to_i
    attempted=td_list[hash_cols["attempted"]].inner_text.to_i
    failed=td_list[hash_cols["failed"]].inner_text.to_i
    permfailed=td_list[hash_cols["permfailed"]].inner_text.to_i
    completed=td_list[hash_cols["completed"]].inner_text.to_i
    deferred=td_list[hash_cols["deferred"]].inner_text.to_i
    
    act_attempt=attempted+failed+completed+blocked
    act_competed=completed
    value_hash=Hash[3,act_attempt,4,act_competed]    
    update_file file_path,value_hash
    
  end
}
