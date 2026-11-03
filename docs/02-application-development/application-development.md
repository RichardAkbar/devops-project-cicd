# Portfolio Website Development

## 1. Objective

Develop a personal portfolio website using HTML5 and CSS3 as the application for the End-to-End DevSecOps CI/CD Pipeline project.

## 2. Personal Information

| Field | Value |
|---|---|
| Full Name | Richard Jabarul Akbar |
| Display Name | Richard Akbar |
| Role | DevOps Engineer |
| GitHub | RichardAkbar |

## 3. Technology Stack

| Component | Technology |
|---|---|
| Frontend | HTML5 |
| Styling | CSS3 |
| Development Server | Python HTTP Server |
| Version Control | Git |
| Repository | GitHub |

## 4. Application Structure

```text
app/
├── index.html
├── css/
│   └── style.css
└── assets/
    └── images/
```

## 5. Implementation

The portfolio website includes:

- Home / Hero Section
- About Me
- Technical Skills
- Featured Projects
- Contact
- Responsive CSS layout
- Dark navy theme with blue accent color

## 6. Testing and Verification

### HTTP Response Test

Command:

```bash
curl -I http://localhost:8000
```

Expected Result: HTTP 200 OK.

Actual Result: Pending final verification.

### HTML Content Test

Command:

```bash
curl -s http://localhost:8000 | grep -E 'Richard Jabarul Akbar|DevOps Engineer'
```

Expected Result: Portfolio identity is present in the HTML response.

Actual Result: Pending final verification.

### CSS Availability Test

Command:

```bash
curl -I http://localhost:8000/css/style.css
```

Expected Result: HTTP 200 OK and Content-Type text/css.

Actual Result: Pending final verification.

## 7. Evidence

### Portfolio Website Preview

![Portfolio Website](../../evidence/03-application-development/portfolio-preview.png)

## 8. GitHub Integration

Repository: https://github.com/RichardAkbar/devops-project-cicd

Commit: Pending.

## 9. Conclusion

The portfolio application has been developed using HTML5 and CSS3. It will be used as the application source for subsequent Dockerization and CI/CD implementation.

## 10. Completion Criteria

- [x] HTML homepage created.
- [x] CSS styling implemented.
- [x] Personal identity configured.
- [x] Website displayed in browser.
- [ ] HTTP tests completed.
- [ ] Responsive layout verified.
- [ ] Screenshot evidence saved.
- [ ] Documentation committed.
- [ ] Source code pushed to GitHub.
