# Postal Code to Electoral District Web Service

[![Dependency Status](https://gemnasium.com/opennorth/postal_code_to_edid_webservice.png)](https://gemnasium.com/opennorth/postal_code_to_edid_webservice)

**NOTICE: This service is deprecated. Use [Represent](https://represent.opennorth.ca/).**

This service receives a postal code and returns the federal electoral districts matching the postal code as JSON. Since electoral districts change names regularly, we return the unchanging ID used by Elections Canada, which you can then map to a name.

Names are available at [Elections Canada](http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=e#change).

A postal code matching a single electoral district:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/A1A1A1
    ["10007"]

A postal code matching multiple electoral districts:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0
    ["35012","35025","35040","35052","35063","35064","35087"]

As JSONP:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0/jsonp?callback=success
    success([35012,35025,35040,35052,35063,35064,35087])

As CSV:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0/csv
    35012,35025,35040,35052,35063,35064,35087

An error for a nonexistent postal code:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/H0H0H0
    {"error":"Postal code could not be resolved","link":"http://www.elections.ca/scripts/pss/FindED.aspx?PC=H0H0H0&amp;image.x=0&amp;image.y=0"}

An error for an invalid postal code:

    $ curl https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/Z1Z1Z1
    {"error":"Postal code invalid"}

This project uses [GovKit-CA](https://github.com/opennorth/govkit-ca#readme) to determine electoral districts from postal codes. Credit to [Daniel Haran](https://github.com/danielharan) for the [first version](https://github.com/danielharan/postal_code_to_edid_webservice) of this project.

Copyright (c) 2011 Open North Inc., released under the MIT license
