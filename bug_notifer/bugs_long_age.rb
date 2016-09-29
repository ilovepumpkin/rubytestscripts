require 'common'
require 'ParseDate'
require 'date'

query_url="https://nsjazz.raleigh.ibm.com:8002/jazz/resource/itemOid/com.ibm.team.workitem.query.QueryDescriptor/_BY0K0BRnEd662N9O3sxqYQ?_mediaType=text/csv"

cc_emails=['shenrui@cn.ibm.com','stephan.hesmer@de.ibm.com','v2kris@us.ibm.com','chengfbj@cn.ibm.com','david_osofsky@us.ibm.com','shiwcsdl@cn.ibm.com']
subject="Your bugs are too old"
receiver_type="owner"
bug_notifer=BugNotifier.new(query_url,receiver_type,subject,cc_emails)
bug_notifer.debug=true
bug_notifer.notify{|bug|
    true if bug.age>=LONG_AGE
}

