require 'common'

file_path="mmfvt_defect_by_severity_overtime.csv"
sev12_url='https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_jBe7QALnEd6qDbjv0e_uJQ?_mediaType=text/csv'
sev34_url='https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_1mopoQR1Ed6qDbjv0e_uJQ?_mediaType=text/csv'

sev12_bug_count=get_bug_count(sev12_url)
sev34_bug_count=get_bug_count(sev34_url)
all_bug_count=sev12_bug_count+sev34_bug_count
value_hash=Hash.new
value_hash[4]=all_bug_count
value_hash[5]=sev12_bug_count
value_hash[6]=sev34_bug_count
update_file file_path,value_hash