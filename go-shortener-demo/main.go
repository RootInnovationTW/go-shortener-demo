// main.go
package main

import (
    "context"
    "fmt"
)

func main() {
    ctx := context.Background()

    db, err := Dial(ctx, "file:links.db?mode=rwc")
    if err != nil {
        panic(err)
    }

    shortener := NewShortener(db)

    // 建立一個短網址
    key, err := shortener.Shorten(ctx, Link{
        Key: "foo",
        URL: "https://golang.org",
    })
    if err != nil {
        panic(err)
    }
    fmt.Println("Shortened key:", key)

    // 解析短網址
    lnk, err := shortener.Resolve(ctx, "foo")
    if err != nil {
        panic(err)
    }
    fmt.Println("Resolved URL:", lnk.URL)
}
