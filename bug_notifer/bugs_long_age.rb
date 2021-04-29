require 'common'
require 'ParseDate'
require 'date'

query_url="https://nsjazz.raleigh.jcn.com:8002/jazz/resource/itemOid/com.jcn.team.workitem.query.QueryDescriptor/_BY0K0BRnEd662N9O3sxqYQ?_mediaType=text/csv"

cc_emails=['xxx@yyy.com','stephan.hesmer@de.jcn.com','v2kris@us.jcn.com','chengfbj@yyy.com','david_osofsky@us.jcn.com','shiwcsdl@yyy.com']
subject="Your bugs are too old"
receiver_type="owner"
bug_notifer=BugNotifier.new(query_url,receiver_type,subject,cc_emails)
bug_notifer.debug=true
bug_notifer.notify{|bug|
    true if bug.age>=LONG_AGE
}

