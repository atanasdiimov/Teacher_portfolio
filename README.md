# Учителско портфолио

Статичен сайт, подготвен за публикуване чрез GitHub Pages.

## Най-лесният начин за публикуване

1. Влезте в GitHub и създайте ново публично хранилище.
2. Качете всички файлове и папки от тази папка в новото хранилище.
3. Отворете `Settings` -> `Pages`.
4. В секцията `Build and deployment` изберете една от двете възможности:
   - `Source: GitHub Actions` - препоръчително, ако сте качили и скритата папка `.github`.
   - `Source: Deploy from a branch` -> `Branch: main` -> `/(root)` - ако сте качили само HTML, CSS, JS и `assets`.
5. Изчакайте 1-3 минути и презаредете страницата `Pages`.

## Какъв ще е адресът

- Ако хранилището се казва например `teacher-portfolio`, адресът ще бъде:
  `https://YOUR-USERNAME.github.io/teacher-portfolio/`
- Ако хранилището се казва `YOUR-USERNAME.github.io`, адресът ще бъде:
  `https://YOUR-USERNAME.github.io/`

## Важно при качване през браузър

- Ако искате автоматично публикуване чрез `GitHub Actions`, включете и скритата папка `.github`.
- Ако не виждате скритите файлове в Windows Explorer, активирайте `View` -> `Show` -> `Hidden items`.
- Файлът `index.html` е началната страница на сайта.

## Какво вече е подготвено

- Начална страница: `index.html`
- Статични ресурси: `assets/`
- Автоматичен деплой: `.github/workflows/deploy-pages.yml`
