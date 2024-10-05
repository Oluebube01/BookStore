// Bookstore Assignment in cairo (Week 3)
// The challenge
// Users should be able to:
//  get the details of a book when queried(read)
//  buy a book(write)
// Program should be able to:
//  update store when new stock is addded (write)
// Admin should be able to:
//  add new book
//  update stock of a book
//  update price of a book

// Solutions
//1. import utility from starknet core
use core::starknet::ContractAddress;

// 2. define a book struct: this struct hold the 
//    details for each book, such as title, price and
// stock
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book {
    title: felt252,
    price: u256,
    stock: u256
}

//3. define the interface
#[starknet::interface]
pub trait IFomastore<TContractState> {
    // defining admin functions(external)
    fn add_book(
        ref self: TContactState, 
        book_id: felt252, 
        title: felt252, 
        price: u256, 
        initial_stock: u256
    ); //this function allows the store admin to 
        //add a new book to the inventory
    fn update_stock(
        ref self: TContractState, 
        book_id: felt252, 
        new_stock: u256
    ); //this function allows the admin to 
        //update the stock for a particular book
    fn update_price(
        ref self: TContactState, 
        book_id: felt252, 
        new_price: u256
    ); //this function allows the admin to 
        //update the price for a specific book


    // defining customer functions(external)
    fn buy_book(
        ref self: TContactState, book_id: felt252, customer_address: ContractAddress
    ); //this function handles the purchase of a book by reducing stock and processing the sale.
    fn place_special_order(
        ref self: TContactState, book_id: felt252, customer_address: ContractAddress
    ); //this function allows a customer to place an order for a book that is our of stock
    fn redeem_gift_card(
        ref self: TContractState, customer_address: ContractAddress, gift_card_value: u256
    ); //this function allows a customer to redeem their gift card balance to make purchases


    // defining view functions
    fn check_stock(
        self: @TContactState, book_id: felt252
    ) -> u256; //this function allows anyone to check the stock of a particular book
    fn check_price(
        self: @TContactState, book_id: felt252
    ) -> u256; //this function alloes anyone to check the price of a particular book
    fn get_book_details(
        self: @TContactState, book_id: felt252
    ) -> felt252; //this function allows anyone to retreive the details of a particular book (title, price and stock)
    fn check_special_order(
        self: @TContactState, customer_address: ContractAddress, book_id: felt252
    ) -> felt252; //this function allows a customer to check the status of their special order
    fn check_gift_card_balance(self: @TContactState, customer_address: ContractAddress) -> u256;
}
// 4. define the contract itself
#[starknet::contract]
pub mod Fomastore {
    // 5. import the interface and book struct using super call
    use super::{IFomastore, Book};
    // 6. import more utilities from starknet core
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };
    // 7. define storage for structs
    #[storage]
    struct Storage {
        book_inventory: Map<felt252, felt252>, // mapping bookid => book struct
        special_orders: Map<
            (ContractAddress, felt252), felt252
        >, //mapping customer address => book id,  status
        gift_card_balance: Map<
            ContractAddress, u256
        >, //mapping customer address and returning balance
        admin_address: ContractAddress,
    }
    // 8. define events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookPurchased: BookPurchased,
    }
    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        book_id: felt252,
        title: felt252,
        price: u256,
        stock: u256
    }
    #[derive(Drop, starknet::Event)]
    struct BookPurchased {
        book_id: felt252,
        customer_address: ContractAddress,
        price: u256,
    }
    // 9. control access using contructor
    #[constructor]
    fn constructor(ref self: ContractState, admin_address: ContractAddress) {
        self.admin_address.write(admin_address);
    }
    // 10. implementing our already defined functions
    #[external(v0)]
    impl FomastoreImpl of IFomastore<ContractState> {
        fn add_book(
            ref self: ContactState,
            book_id: felt252,
            title: felt252,
            price: u256,
            initial_stock: u256
        ) {
            let caller_address = get_caller_address();
            let admin_address = self.admin_address.read();
            assert(caller_address == admin_address, 'Only admin can add books');

            let new_book = Book { title: title, price: price, stock: stock, };

            self.book_inventory.write(book_id, new_book);

            // emit bookAdded event
            self.emit(bookAdded { book_id, title, price, stock });
        }
        fn update_stock(ref self: ContractState, book_id: felt252, new_stock: u256) {
            let book = book_inventory.read(book_id);
            let updated_book = Book { title: book.title, price: book.price, stock: new_stock };
            self.book_inventory.write(book_id, updated_book);
        }
        fn update_price(ref self: ContactState, book_id: felt252, new_price: u256) {
            let book = book_inventory.read(book_id);

            let updated_book = Book { title: book.title, price: new_price, stock: book.stock };
            self.book_inventory.write(book_id, updated_book);
        }
        fn buy_book(ref self: TContactState, book_id: felt252, customer_address: ContractAddress) {
            let current_book = self.book_inventory.read(book_id);
            assert(current_book.stock <= 0, 'Book is out of Stock!');

            let new_stock = current_book.stock - 1;
            let updated_book = Book {
                title: current_book.title, price: current_book.price, stock: new_stock
            };
            self.book_inventory.write(book_id, updated_book);

            // emit bookpurchased event
            self.BookPurchased.emit(book_id, customer_address, current_book.price);
        }
        fn place_special_order(
            ref self: TContactState, book_id: felt252, customer_address: ContractAddress
        ) {
            // Record the special order with status 1 == ordered
            self.special_orders.write(customer_address, book_id, 1);
        }
        fn redeem_gift_card(
            ref self: TContractState, customer_address: ContractAddress, gift_card_value: u256
        ) {
            let current_balance = self.gift_card_balance.read(customer_address);

            // add the gift card value to the customer's current balance
            let new_balance = current_balance + gift_card_balance;
            self.gift_card_balance.write(customer_address, new_balance);
        }
    }
    #[view(v0)]
    impl FomastoreviewImpl of IFomastore<ContractState> {
        fn check_stock(self: @ContactState, book_id: felt252) -> u256 {
            let (_, _, stock) = self.book_inventory.read(book_id);
            return (stock);
        }
        fn check_price(self: @ContactState, book_id: felt252) -> u256 {
            let (_, price, _) = book_inventory.read(book_id);
            return (price);
        }
        fn get_book_details(self: @ContactState, book_id: felt252) -> felt252 {
            let current_book = self.book_inventory.read(book_id);
            return (current_book);
        }
        fn check_special_order(
            self: @ContactState, customer_address: ContractAddress, book_id: felt252
        ) -> felt252 {
            let (book_id, status) = special_orders.read(customer_address);
            return (book_id, status);
        }
        fn check_gift_card_balance(self: @ContactState, customer_address: ContractAddress) -> u256 {
            let balance = gift_card_balance.read(customer_address);
            return (balance);
        }
    }
}

