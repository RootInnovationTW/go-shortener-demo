#!/bin/bash
set -e

# 專案名稱
PROJECT="go-shortener-demo"

# 建立目錄
mkdir -p $PROJECT
cd $PROJECT

# 建立 go.mod
cat > go.mod <<'EOF'
module github.com/RootInnovationTW/go-shortener-demo

go 1.24

require modernc.org/sqlite v1.38.0
EOF

# 建立 schema.sql
cat > schema.sql <<'EOF'
CREATE TABLE IF NOT EXISTS links (
    short_key VARCHAR(16) PRIMARY KEY,
    uri TEXT NOT NULL
);
EOF

# 建立 db.go
cat > db.go <<'EOF'
// db.go
package main

import (
    "context"
    "database/sql"
    "embed"
    "fmt"

    _ "modernc.org/sqlite"
)

//go:embed schema.sql
var schema string

func Dial(ctx context.Context, dsn string) (*sql.DB, error) {
    db, err := sql.Open("sqlite", dsn)
    if err != nil {
        return nil, fmt.Errorf("opening: %w", err)
    }
    if err := db.PingContext(ctx); err != nil {
        return nil, fmt.Errorf("pinging: %w", err)
    }

    if _, err := db.ExecContext(ctx, schema); err != nil {
        return nil, fmt.Errorf("applying schema: %w", err)
    }

    return db, nil
}
EOF

# 建立 shortener.go
cat > shortener.go <<'EOF'
// shortener.go
package main

import (
    "context"
    "database/sql"
    "fmt"
)

// Link represents a shortened link
type Link struct {
    Key string
    URL string
}

// Shortener 提供短網址服務
type Shortener struct {
    db *sql.DB
}

// NewShortener 建立一個新的短網址服務
func NewShortener(db *sql.DB) *Shortener {
    return &Shortener{db: db}
}

// Shorten 將 URL 縮短並存入資料庫
func (s *Shortener) Shorten(ctx context.Context, lnk Link) (string, error) {
    if lnk.Key == "" {
        return "", fmt.Errorf("key is empty")
    }
    _, err := s.db.ExecContext(ctx,
        `INSERT INTO links (short_key, uri) VALUES (?, ?)`,
        lnk.Key, lnk.URL)
    if err != nil {
        return "", fmt.Errorf("saving: %w", err)
    }
    return lnk.Key, nil
}

// Resolve 根據 key 找回原始 URL
func (s *Shortener) Resolve(ctx context.Context, key string) (Link, error) {
    var uri string
    err := s.db.QueryRowContext(ctx,
        `SELECT uri FROM links WHERE short_key = ?`,
        key).Scan(&uri)
    if err == sql.ErrNoRows {
        return Link{}, fmt.Errorf("not found")
    }
    if err != nil {
        return Link{}, fmt.Errorf("retrieving: %w", err)
    }
    return Link{Key: key, URL: uri}, nil
}
EOF

# 建立 main.go
cat > main.go <<'EOF'
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
EOF

echo "✅ $PROJECT 專案建立完成！"
echo "👉 下一步："
echo "cd $PROJECT"
echo "go mod tidy"
echo "go run ."
echo
echo "GitHub 初始化："
echo "git init && git add . && git commit -m 'init shortener demo'"
echo "git branch -M main"
echo "git remote add origin git@github.com:RootInnovationTW/go-shortener-demo.git"
echo "git push -u origin main"

