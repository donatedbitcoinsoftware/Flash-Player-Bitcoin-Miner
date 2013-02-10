# Flash Player Bitcoin Miner
#
# This is the Bitcoin mining pool proxy service.
# Flash player code cannot connect to anything except for the originating host
# so to use any existing mining pool it was necessary to do it via a proxy service.
#
# When an HTTP GET request is made it will redirect to an example HTML file
# which demonstrates the use of the Flash Player Bitcoin Miner.
#
# The HTTP POST requests are simply channeled between the Flash Player file
# and the mining pool configured in the HTML file.
#
# This code is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This code is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for
# more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with code. If not, see <http://www.gnu.org/licenses/>.

from google.appengine.api             import urlfetch
from google.appengine.ext             import webapp
from google.appengine.ext.webapp.util import run_wsgi_app

class MainPage(webapp.RequestHandler):
    def post(self):
        host = self.request.get('host', '')
        port = self.request.get('port', '')
        response = urlfetch.fetch(
            url='http://%s:%s' % (host, port),
            payload=self.request.body,
            method=urlfetch.POST,
            deadline=1,
            headers={'Authorization': self.request.headers['Authorization']})
        self.response.set_status(response.status_code)
        self.response.out.write(response.content)

    def get(self):
        self.redirect('/html/test.html')

application = webapp.WSGIApplication([('/proxy', MainPage)], debug=False)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
