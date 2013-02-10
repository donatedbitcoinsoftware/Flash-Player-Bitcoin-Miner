# Flash Player Bitcoin Miner
#
# This builds the Flash miner:
# - First the C code of the miner (using Adobe Alchemy)
# - Then the ActionScript code for communication with mining pool
#   while also linking the miner build earlier (using Adobe Flex SDK)
# Warning: Do not forget to run alc-on before make
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

ALL: app

app:
	gcc ../native/miner.c -O3 -Wall -swc -o miner.swc
	mxmlc -debug=true -library-path+=miner.swc --target-player=11.1.0 -default-frame-rate=24 -static-link-runtime-shared-libraries=true miner.as
	@cp miner.swf ../proxy/swf/
	@rm miner.s* > /dev/null

