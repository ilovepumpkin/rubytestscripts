require 'common'

file_path="mmfvt_defect_scurve.csv"
allbug_url='/jazz/resource/itemOid/com.jcn.team.workitem.query.QueryDescriptor/_xejJ0PgHEd2qDbjv0e_uJQ?_mediaType=text/csv'
validbug_url='/jazz/resource/itemOid/com.jcn.team.workitem.query.QueryDescriptor/_olyEABN_Ed662N9O3sxqYQ?_mediaType=text/csv'

all_bug_count=get_bug_count(allbug_url)
valid_bug_count=get_bug_count(validbug_url)
value_hash=Hash[3=>all_bug_count,4=>valid_bug_count]
update_file file_path,value_hash