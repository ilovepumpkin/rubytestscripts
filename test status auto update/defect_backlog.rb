require 'common'

file_path="mmfvt_defect_backlog.csv"
fix_url='https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_zFzM0OYyEd25X9DZJXTRrg?_mediaType=text/csv'
resolved_url='https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_UMCV0OafEd25X9DZJXTRrg?_mediaType=text/csv'
closed_url='https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/__KajAP2QEd2qDbjv0e_uJQ?_mediaType=text/csv'

fix_count=get_bug_count(fix_url)
resolved_count=get_bug_count(resolved_url)
closed_count=get_bug_count(closed_url)
total_count=fix_count+resolved_count
value_hash=Hash.new
value_hash[1]=fix_count
value_hash[2]=resolved_count
value_hash[3]=closed_count
value_hash[4]=total_count
update_file file_path,value_hash