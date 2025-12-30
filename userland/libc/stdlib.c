#include "stdlib.h"
#include "syscall.h"

struct slot_header;
typedef struct slot_header slot_header_t;

#include "stddef.h"
#include <stdbool.h>
#include "string.h"

struct slot_header
{
    size_t slot_size;
    bool used;
    slot_header_t *next;
};

struct page_header;
typedef struct page_header page_header_t;

#include "stddef.h"

struct page_header
{
    size_t available_size;
    page_header_t *next;
};


static page_header_t* first_page = NULL;

#define MIN_PAGE_SIZE 4096


page_header_t* alloc_page(size_t size)
{
    printf("Alloc_Page\n");
    size_t page_size = ((size + sizeof (page_header_t) + MIN_PAGE_SIZE - 1) / MIN_PAGE_SIZE) * MIN_PAGE_SIZE;
    page_header_t *header = (page_header_t *)mmap(NULL, page_size, 0, 1, 0, 0);
    header->available_size = page_size - sizeof (page_header_t);
    header->next=NULL;

    slot_header_t *slot_header = (slot_header_t *)(header + 1);
    slot_header->next = NULL;
    slot_header->slot_size = header->available_size - sizeof(slot_header_t);
    slot_header->used = false;
    printf("slot_header: %d\n", slot_header->slot_size);
    return header;
}

slot_header_t* find_slot_for_size (size_t slot_size)
{
    page_header_t *current_page = first_page;
    size_t to_allocate = slot_size + sizeof (slot_header_t);
    printf("first_page: %d\n", first_page);
    if (first_page == NULL)
    {
        first_page = alloc_page(to_allocate);
        return (slot_header_t *)((char*)first_page + sizeof (page_header_t));
    }
    
    page_header_t  *prev_page = first_page;
    while (current_page != NULL)
    {
        slot_header_t *current_slot = (slot_header_t *)((char*)current_page + sizeof (page_header_t));
        for (; current_slot != NULL; current_slot = current_slot->next)
        {
            if (current_slot->used)
                continue;
            if (current_slot->slot_size < slot_size)
                continue;
            return current_slot;
        }
        prev_page = current_page;
        current_page = current_page->next;
    }

    prev_page->next = alloc_page(to_allocate);
    return (slot_header_t *)((char*)prev_page->next + sizeof (page_header_t));
}

#define MIN_SLOT_SIZE 64
void alloc_in_slot(size_t to_allocate, slot_header_t *slot)
{
    slot->used = true;
    if (slot->next != NULL)
        return;
    
    if ((slot->slot_size - to_allocate) > MIN_SLOT_SIZE + sizeof (slot_header_t))
    {
        slot_header_t *next_slot = (slot_header_t *) (((char*)slot) + to_allocate + sizeof (slot_header_t));
        next_slot->next = NULL;
        printf("Tanguy: slot_size %d, to_allocate %d\n", slot->slot_size, to_allocate);
        next_slot->slot_size = slot->slot_size - to_allocate - sizeof (slot_header_t);
        next_slot->used = false;
        slot->slot_size = to_allocate;
        slot->next = next_slot;
    }
}

void print_page_header(page_header_t *header)
{
    printf("page_size: %d\n", header->available_size);
}

void print_slot_header(slot_header_t *header)
{
    printf("  | %d [%d] : %s\n", header, header->slot_size, header->used ? "used" : "free");
}

void print_info(void)
{
    if (first_page == NULL)
    {
        printf("first_page is NULL");
    }

    for (page_header_t *current = first_page; current != NULL; current = current->next)
    {
        print_page_header(current);
        for (slot_header_t *current_slot = (slot_header_t *)(current + 1); current_slot != NULL; current_slot = current_slot->next)
        {
            print_slot_header(current_slot);
        }
    }
}

void *malloc(size_t size)
{
    printf("malloc(%d)", size);
    size_t to_allocate = ((size + 31) / 32) * 32;
    slot_header_t *slot = find_slot_for_size(to_allocate);
    alloc_in_slot(to_allocate, slot);
    
    // print_info();
    return (void*)((char*)slot + sizeof (slot_header_t));
}

void stdlib_init(void)
{
    first_page = NULL;
}

void free(void *ptr)
{
    if (ptr == NULL)
    {
        return;
    }
    printf("Freeing %d\n", ptr);
    slot_header_t* slot = (slot_header_t*)(ptr - sizeof(slot_header_t));
    slot->used = false;
}

void *calloc(size_t nmemb, size_t size)
{
    void *ptr = malloc(nmemb * size);
    memset(ptr, 0, nmemb * size);
    return ptr;
}

void *realloc(void *ptr, size_t size)
{
    if (ptr == NULL)
    {
        return malloc (size);
    }

    if (size == 0)
    {
        free (ptr);
        return NULL;
    }
    slot_header_t* slot = (slot_header_t*)(ptr - sizeof(slot_header_t));
    if (slot->slot_size > size)
        return ptr;
    void *new_ptr = malloc(size);
    memcpy(new_ptr, ptr, slot->slot_size);
    free(ptr);
    return ptr;
}

void exit(int status)
{
    while (1)
    {
        /* code */
    }
}

int atoi(const char *nptr)
{
    if (nptr == NULL)
        return 0;
    int result = 0;
    for (; *nptr != '\0'; nptr++)
    {
        result = (result * 10) + (*nptr - '0');
    }

    return result;
}

long atol(const char *nptr)
{
    if (nptr == NULL)
        return 0;
    long result = 0;
    for (; *nptr != '\0'; nptr++)
    {
        result = (result * 10) + (*nptr - '0');
    }

    return result;
}

long long atoll(const char *nptr)
{
    if (nptr == NULL)
        return 0;
    long long result = 0;
    for (; *nptr != '\0'; nptr++)
    {
        result = (result * 10) + (*nptr - '0');
    }

    return result;
}

double atof(const char *nptr)
{
    if (nptr == NULL)
        return 0.0;

    double result = 0;
    for (; *nptr != '\0' && *nptr != '.'; nptr++)
    {
        result = (result * 10) + (*nptr - '0');
    }
    
    if (*nptr == '\0')
    {
        return 0.0;
    }

    double divider = 10;
    for (; *nptr != '\0' && *nptr != '.'; nptr++)
    {
        result = result + ((*nptr - '0')/divider);
        divider *= 10;
    }

    return result;
}

