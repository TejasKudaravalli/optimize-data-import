# Use the official PostgreSQL image
FROM postgres:15

# Set environment variables for PostgreSQL
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres

# Copy initialization SQL scripts (if any)
COPY sql/init.sql /docker-entrypoint-initdb.d/

# Expose default PostgreSQL port
EXPOSE 5432
