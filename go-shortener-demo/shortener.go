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
