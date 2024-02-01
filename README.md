# Build Mkdocs Based Docs Site Static Locally

This repo helps you build the Mkdocs Based Docs site (all Languages) locally as a static site.

It uses a bash script to build the entire static structure, and then the npm package `http-server` to serve the static site locally.

**If you are using MacOS you should install `gcp` package by running `brew install coreutils`! The check is done via `uname` and the return value is compared with `Linux` for Ubuntu. You'll also need to install `gnu-sed` which you can do by running `brew install gnu-sed`.**

## Getting Started - Building the File Structure

**This repo assumes you have all the dependencies of the Mkdocs repo installed!**

To get started clone the repo:

```
git clone https://github.com/papermoonio/build-docs-site.git
cd build-docs-site
```

Then you can run the bash file `buildSite.sh` - You might need to change execution permissions by doing the following:

```
chmod u+x ./buildSite.sh
```

With the right execution permissions, run:

```
./buildSite.sh -d
```

Where `-d` can be either `-d moonbeam` or `-d tanssi`. 

You can also provide the flag:
 - `-f` to force a new build
 - `-m "<branch_name"` for a specific branch in the MkDocs repo, default is moonbeam: `master` - tanssi: `main`
 - `-e  "<branch_name>"` to build a specific branch in the EN repo, default is moonbeam: `master` - tanssi: `main`
 - `-o "<en_owner>"` to build from a specific `moonbeam-docs` repo owner, default is moonbeam: `moonbeam-foundation` - tanssi: `moondance-labs`
 - `-c "<branch_name>"` to build a specific branch in the CN repo, default is moonbeam: `master`
 - `-s "<cn_owner>"` to build from a specific `moonbeam-docs-cn` repo owner, default is moonbeam: `moonbeam-foundation`

For example:

```
./buildSite.sh -f -m "master" -e "master" -o "moonbeam-foundation" -c "master" -s "moonbeam-foundation"
```

## Serving the Static Site

Once the file structure has been built, you need to install the npm packages with `yarn` or `npm i`:

```
yarn
```

Or:

```
npm i
```

Then you can serve the static site in port `8000` with the following command:

```
yarn start
```

Or you can run the command manually with:

```
npx http-server ./moonbeam-docs-static/ -p 8000
```

You can find more info on `http-server` [here](https://www.npmjs.com/package/http-server).
