require 'common'

query_url="https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_PR-V8P8REd2qDbjv0e_uJQ?_mediaType=text/csv"

cc_emails=['shenrui@cn.ibm.com']
subject="Please verify your bugs timely"
receiver_type="creator"
bug_notifer=BugNotifier.new(query_url,receiver_type,subject,cc_emails)
bug_notifer.debug=false
bug_notifer.notify{|bug|
    true
}

