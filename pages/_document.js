import Document, { Html, Head, Main, NextScript } from "next/document";

class MyDocument extends Document {
  static async getInitialProps(ctx) {
    const initialProps = await Document.getInitialProps(ctx);
    return { ...initialProps };
  }

  render() {
    return (
      <Html>
        <Head>
          <meta name="description" content="Mercurials is an on-chain generative art project built on Ethereum." />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta property="og:title" content="Mercurials" />
          <meta property="og:type" content="website" />
          <meta property="og:url" content="https://mercurials.wtf" />
          <meta
            property="og:description"
            content="Mercurials is an on-chain generative art project built on Ethereum."
          />
          <meta property="og:image" content="https://mercurials.wtf/og-image.png" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="preconnect" href="https://fonts.googleapis.com" />
          <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="true" />
          <link
            href="https://fonts.googleapis.com/css2?Lato:wght@400;700&display=swap"
            rel="stylesheet"
          />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}

export default MyDocument;

