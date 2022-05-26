---
categories: homepage
---

[GitHub Pages](https://pages.github.com/) are an easy and free way to host a web site (like this one!). By default, GitHub will host your site at `<your_username>.github.io`. The Pages documentation also covers setting up a [custom domain](https://help.github.com/articles/using-a-custom-domain-with-github-pages/) for your site, which can be any of the following combinations:

1. your apex domain (e.g. khouri.ca)
2. the `www` subdomain (e.g. www.khouri.ca)
3. both the apex and `www` domains
4. a custom subdomain (e.g. marc.khouri.ca)

If you have a site like mine, where all the content is a non-www subdomain (i.e. `http://marc.khouri.ca`), you probably want users who type in your apex domain (i.e. `http://khouri.ca`) or the `www` subdomain to reach your subdomain. You may not have more than one custom subdomain for a GitHub Pages website, but you can make visitors reach your content succesfully, as I explain at the bottom of the post.

## Why you can't have multiple custom subdomains

To understand why two subdomains can not point to the same GitHub pages site, we have to understand some details about shared web hosting and DNS.

#### Many websites, one server

**Shared web hosting** allows one single web server to host multiple websites with their own domain name. So, `www.domain1.com` and `www.domain2.com` might have one single web server providing *different content* for each site. This server can determine which content to show because the HTTP request from a browser to a server includes the hostname (e.g. domain1.com) as part of the request.

But web browsers do not send their requests to a domain name -- they send their requests to an IP address. When a user browses to `www.domain1.com`, the web browser needs to find the correct IP address to send a request to. The browser makes a DNS request to a DNS server, which responds with the correct IP address. The browser then makes its HTTP request (with `www.domain1.com` as part of the request) to this IP address.

#### Turning a name into an address

There are several types of DNS records, but only 2 are important for this post: `A` and `CNAME` records. `A` records are easy to understand: they map domain name like `www.example.com` to an IP address like `93.184.216.34`. `CNAME` records, on the other hand, point to another domain name. For example, `mail.google.com` has a CNAME pointing to `googlemail.l.google.com`, which has an `A` record pointing to `216.58.218.229`. You can see these records by using the `dig` command:

```
⚡⇒ dig mail.google.com

; <<>> DiG 9.8.3-P1 <<>> mail.google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 36963
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;mail.google.com.       IN  A

;; ANSWER SECTION:
mail.google.com.    323258  IN  CNAME   googlemail.l.google.com.
googlemail.l.google.com. 36 IN  A   216.58.218.229
```

It is important to understand that every DNS requests results in an IP address. So, if I create a `CNAME` record for `www.khouri.ca` which maps to `marc.khouri.ca`, the IP address in the DNS response for `www.khouri.ca` and `marc.khouri.ca` will be the same -- they will both give the IP address for the shared web host that GitHub is using for GitHub Pages. This IP address is the same for all sites running on GitHub Pages.

#### Where there's a problem

Recall from earlier in this post that the shared web host uses the domain name in the HTTP request to determine which content to display. GitHub Pages only allows one single domain name to be configured for a site. I have chosen `marc.khouri.ca`. Even if I make a `CNAME` record for `www.khouri.ca` which maps to `marc.khouri.ca`, when my browser makes the request to the GitHub Pages IP address, it will include `www.khouri.ca` in the header, which GitHub Pages will not know how to interpret.

## The solution: HTTP redirects

The solution is to host a site which has a [HTTP 301 redirect](https://en.wikipedia.org/wiki/HTTP_301) to `marc.khouri.ca`. Then, I can set the DNS records for `www.khouri.ca` and `khouri.ca` to this new site. Any requests to this site will be redirected to `marc.khouri.ca`.

One of the advantages of using GitHub Pages for this web site is that I do not need to maintain a web server, so I do not want to run a web server just to serve my HTTP redirect.

Instead, we can use to [create a static web site](https://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html) for `www.khouri.ca` and `khouri.ca`, and then configure that web site to [redirect all traffic](https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html) to `marc.khouri.ca`.

## The complete picture

The final result looks like this:

- An AWS S3 bucket named `khouri.ca` and `www.khouri.ca`, both configured for static web hosting to redirect all requests to another host name.
- A DNS CNAME record for `khouri.ca` and `www.khouri.ca`, both pointing to their respective AWS S3 static web sites.
- A DNS CNAME record for `marc.khouri.ca`, pointing to `mnkhouri.github.io`.

With this setup, a user who enters `khouri.ca/posts` in their web browser will get redirected to `marc.khouri.ca/posts`, which will be served by my GitHub Pages web site.
