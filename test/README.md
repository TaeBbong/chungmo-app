# Test Codes for Reliable Chungmo-App

This document introduces test scope for chungmo-app.

## Test #1 : Try to create new schedule from link, success at once.

- **Given** shown up CreatePage with empty textfield
- **When** a user types valid link to textfield and submit
- **Then** few seconds later(less then 20s) result shows

## Test #2 : Try to create new schedule from link, fail then success with retry.

- **Given** shown up CreatePage with empty textfield
- **When** a user types valid link to textfield and submit
- **Then** few seconds later(less then 40s) result shows with retries at backend.

## Test #3 : Try to read schedules from calendar view.

- **Given** nothing
- **When** a user enters to CalendarView
- **Then** monthly schedules load on calendar

## Test #4 : Try to read schedules from list view.

- **Given** a user entered to CalendarView
- **When** a user enters to CalendarListView
- **Then** all schedules load on list

## Test #5 : Try to read schedules from calendar view, go back to home then read again.

- **Given** a user already entered to CalendarView with schedules loaded
- **When** a user get backs to CreatePage then goes to CalendarView again
- **Then** monthly schedules load on calendar exact same with given status.

## Test #6 : Try to modify schedule from detail page.

- **Given** a user entered to DetailPage with a schedule
- **When** a user modifies schedule
- **Then** a schedule updates, even get backs to CalendarView and CalendarListView

## Test #7 : Try to delete schedule from detail page.

- **Given** a user entered to DetailPage with a schedule
- **When** a user deletes schedule
- **Then** a schedule deletes, even get backs to CalendarView and CalendarListView
