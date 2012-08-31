# Postal Code to Electoral District Web Service

[![Dependency Status](https://gemnasium.com/opennorth/postal_code_to_edid_webservice.png)](https://gemnasium.com/opennorth/postal_code_to_edid_webservice)

Allow your users to find their electoral district based on their postal code by
integrating this web service into your web site. From an electoral district, you
can determine the user's Member of Parliament, voting poll, and other
information.

# Usage

Sending a request, as below, returns the electoral districts within a postal
code as JSON. Because electoral districts change names regularly, we return the
unchanging ID used by Elections Canada, which you can then map to a district
name. Official district names are available at
[Elections Canada](http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=e#change),
which are cached here as
[riding-names.csv](https://github.com/opennorth/postal_code_to_edid_webservice/blob/master/riding-names.csv).
Microsoft Excel doesn't support CSVs containing UTF-8 characters.

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/A1A1A1
    ["10007"]

It also works if a postal code contains multiple electoral districts:

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/K0A1K0
    ["35012","35025","35040","35052","35063","35064","35087"]

You can alternatively get the electoral districts as CSV:

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/K0A1K0/csv
    35012,35025,35040,35052,35063,35064,35087

There is even JSONP support:

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/K0A1K0/jsonp?callback=success
    success([35012,35025,35040,35052,35063,35064,35087])

Your web site should be able to handle the following errors in case your user inputs an invalid or nonexistent postal code:

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/H0H0H0
    {"error":"Postal code could not be resolved","link":"http://www.elections.ca/scripts/pss/FindED.aspx?PC=H0H0H0&amp;image.x=0&amp;image.y=0"}

    $ curl http://postal-code-to-edid-webservice.heroku.com/postal_codes/Z1Z1Z1
    {"error":"Postal code invalid"}

# Deployment

You can run your own copy of this web service if you like. You just need an
environment in which Rack apps can run, like Passenger, Mongrel, Thin, Unicorn,
etc. This web service currently runs on [Heroku](http://heroku.com/), which,
assuming you have the Heroku gem installed, you can deploy like:

    git clone http://github.com/opennorth/postal_code_to_edid_webservice.git
    heroku create MY_APP_NAME
    git push heroku master

# About

This web service is powered by Open North's 
[GovKit-CA](https://github.com/opennorth/govkit-ca#readme) gem. For more
information on how this web service determines electoral districts from postal
codes, please see that project's page. Credit to
[Daniel Haran](https://github.com/danielharan) for the
[first version](http://github.com/danielharan/postal_code_to_edid_webservice)
of this web service.

Copyright (c) 2011 Open North Inc., released under the MIT license
